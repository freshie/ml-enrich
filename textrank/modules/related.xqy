xquery version "1.0-ml";

module namespace rf = "https://github.com/freshie/ml-enrich/related";

declare namespace mle = "https://github.com/freshie/ml-enrich";

declare option xdmp:mapping "true";

declare variable $dir as xs:string := "/enrich/content/";

declare function rf:related($locale as xs:string, $terms, $phrases, $concepts) {
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
                    cts:directory-query($dir, 'infinity'),
                    cts:element-attribute-value-query(xs:QName('text'), xs:QName('xml:lang'), $locale, "exact"),
                    cts:or-query((
                        for $term in $terms/*
                        let $score := $term/@score
                        let $weight := ($score div $max-term-score ) * 3
                        return (
                            cts:document-fragment-query(
                                cts:element-word-query(xs:QName('mle:term'), $term, (), $weight)
                            )
                        ),
                        for $phrase in $phrases/*
                        let $score := $phrase/@score
                        let $weight := $score div $max-phrases-score * 4
                        return (
                            cts:document-fragment-query(
                                cts:element-word-query(xs:QName('mle:phrase'), $phrase, (), $weight)
                            )
                        ),
                        let $max := fn:max($concepts/@score)
                        for $concept in $concepts/*
                        let $score := $concept/@score
                        let $weight := $score div $max-concepts-score * 2
                        return (
                            cts:document-fragment-query(
                                cts:element-attribute-word-query(xs:QName('mle:concept'), xs:QName('label'), $concept/@label, (), $weight)
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
                for $term in $doc//mle:term
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
                    let $a-phrases := $doc//mle:phrase
                    for $phrase in $phrases/phrase
                    let $a-score := $a-phrases[ . = $phrase ]/@score
                    where fn:exists($a-score)
                    return (
                        $a-score div $max-phrases-score * 4
                    ),
                    let $a-concepts := $doc//mle:concept
                    for $concept in $concepts/concepy
                    let $a-score := $a-concepts[ @label = $concept/@label ]/@score
                    where fn:exists($a-score)
                    return (
                        $a-score div $max-concepts-score * 2
                    )

                ))
            let $uri as xs:string := xdmp:node-uri($doc)
            order by $score descending
            return 
                <match uri="{$uri}" score="{$score}"/>
        return
            $ordered[1 to 15]
    }</related>
};