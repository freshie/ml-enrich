xquery version "1.0-ml";

module namespace rf = "https://github.com/freshie/ml-enrich/related";

import module namespace util = "https://github.com/freshie/ml-enrich/utility" at "/modules/utility.xqy";

declare namespace info = "http://lds.org/code/lds-edit/warehouse/document-info";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare function rf:related-articles($locale as xs:string, $terms, $phrases, $concepts) {
    <related>{
        let $term-map := map:map()
        let $_ :=
            for $term in $terms/term
            return (
                map:put($term-map, $term, xs:double($term/@score))
            )

        let $max-term-score := fn:max(($terms/@score, 1))
        let $max-phrases-score := fn:max(($phrases/@score, 1))
        let $max-concepts-score := fn:max(($concepts/@score, 1))

        let $related :=
            cts:search(fn:collection()/*,
                cts:and-query((
                    cts:directory-query('/warehouse/sites/', 'infinity'),
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('title'), '!=', "", "collation=http://marklogic.com/collation/"),
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/"),
                    cts:element-query(xs:QName('ldse:publish-date'), cts:and-query(())),
                    cts:or-query((
                        for $term in $terms/*
                        let $score := $term/@score
                        let $weight := ($score div $max-term-score ) * 3
                        return (
                            cts:document-fragment-query(
                                cts:element-word-query(xs:QName('ldse:term'), $term, (), $weight)
                            )
                        ),
                        for $phrase in $phrases/*
                        let $score := $phrase/@score
                        let $weight := $score div $max-phrases-score * 4
                        return (
                            cts:document-fragment-query(
                                cts:element-word-query(xs:QName('ldse:phrase'), $phrase, (), $weight)
                            )
                        ),
                        let $max := fn:max($concepts/@score)
                        for $concept in $concepts/*
                        let $score := $concept/@score
                        let $weight := $score div $max-concepts-score * 2
                        return (
                            cts:document-fragment-query(
                                cts:element-attribute-word-query(xs:QName('ldse:concept'), xs:QName('label'), $concept/@label, (), $weight)
                            )
                        )
                    ))
                )),
                ("unfiltered", "score-logtfidf")
            )[ 1 to 50 ]

        let $ordered :=
            for $doc in $related
            let $a-map := map:map()
            let $_ :=
                for $term in $doc//ldse:term
                return (
                    map:put($a-map, $term,xs:double($term/@score))
                )

            let $score :=
                fn:sum((
                    for $term in map:keys($term-map)
                    let $a-score := map:get($a-map, $term)
                    where fn:exists($a-score)
                    return (
                        $a-score div $max-phrases-score * 3
                    ),
                    let $a-phrases := $doc//ldse:phrase
                    for $phrase in $phrases/phrase
                    let $a-score := $a-phrases[ . = $phrase ]/@score
                    where fn:exists($a-score)
                    return (
                        $a-score div $max-phrases-score * 4
                    ),
                    let $a-concepts := $doc//ldse:concept
                    for $concept in $concepts/concepy
                    let $a-score := $a-concepts[ @label = $concept/@label ]/@score
                    where fn:exists($a-score)
                    return (
                        $a-score div $max-concepts-score * 2
                    )

                ))
            let $db-path as xs:string := xdmp:node-uri($doc)
            let $info as element(info:document-info)? := xdmp:document-get-properties($db-path, xs:QName('info:document-info'))
            let $url := rf:get-link($info)
            let $title := $doc/ldse:ldse-meta/ldse:document/@title
            where fn:exists($url) and fn:not( $url = "")
            order by $score descending
            return (
                <match url="{$url}" score="{$score}" title="{$title}"/>
            )
        return (
            $ordered[1 to 15]
        )
    }</related>
};

declare function rf:get-link($info as element(info:document-info)) {
    let $live-domain as xs:string := $info/info:live-domain
    let $url as xs:string := $info/info:url
    let $parts as element(url-parts) := util:get-url-parts($url)
    let $protocol as xs:string := if ($parts/protocol != "") then (   $parts/protocol ) else ( 'https://')
    return (
        fn:concat($protocol, $live-domain, $parts/uri, $parts/params, $parts/hash)
    )
  };