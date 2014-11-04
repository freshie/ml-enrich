xquery version "1.0-ml";

module namespace tr = "https://github.com/freshie/ml-enrich/text-rank";

import module namespace rf = "https://github.com/freshie/ml-enrich/related" at "/modules/related.xqy";

declare namespace mle = "https://github.com/freshie/ml-enrich";

declare variable $dir as xs:string := "/enrich/";
declare variable $dir-query as cts:query := cts:directory-query($dir, 'infinity');

declare function tr:result-to-json($data) {
    let $enrich-object := json:object()
    let $terms :=
        let $terms-array := json:array()
        let $put :=
            for $term in $data/terms/term
            let $term-obj := json:object()
            let $keys := (
                map:put($term-obj, 'score', xs:double($term/@score)),
                map:put($term-obj, 'count', xs:int($term/@count)),
                map:put($term-obj, 'value', xs:string($term))
            )
            return ( json:array-push($terms-array, $term-obj) )
        return ( map:put($enrich-object, 'terms', $terms-array) )

    let $phrases :=
        let $phrases-array := json:array()
        let $put :=
            for $phrase in $data/phrases/phrase
            let $phrase-obj := json:object()
            let $keys := (
                map:put($phrase-obj, 'score', xs:double($phrase/@score)),
                map:put($phrase-obj, 'value', xs:string($phrase))
            )
            return ( json:array-push($phrases-array, $phrase-obj) )
        return ( map:put($enrich-object, 'phrases', $phrases-array) )

    let $entities :=
        let $entities-obj := json:object()
        let $orgs :=
            let $orgs-array := json:array()
            let $push :=
                for $org in $data/entities/organization-entity
                let $org-obj := json:object()
                let $put := (
                    map:put($org-obj, 'count', xs:int($org/@count)),
                    map:put($org-obj, 'value', xs:string($org))
                )
                return ( json:array-push($orgs-array, $org-obj) )
            return ( map:put($entities-obj, "organizations", $orgs-array) )
        let $roles :=
            let $roles-array := json:array()
            let $push :=
                for $role in $data/entities/role-entity
                let $role-obj := json:object()
                let $put := (
                    map:put($role-obj, 'count', xs:int($role/@count)),
                    map:put($role-obj, 'value', xs:string($role))
                )
                return ( json:array-push($roles-array, $role-obj) )
            return ( map:put($entities-obj, "roles", $roles-array) )
        let $locations :=
            let $locations-array := json:array()
            let $push :=
                for $location in $data/entities/location-entity
                let $location-obj := json:object()
                let $put := (
                    map:put($location-obj, 'count', xs:int($location/@count)),
                    map:put($location-obj, 'value', xs:string($location))
                )
                return ( json:array-push($locations-array, $location-obj) )
            return ( map:put($entities-obj, "locations", $locations-array) )
        let $people :=
            let $people-array := json:array()
            let $push :=
                for $person in $data/entities/person-entity
                let $person-obj := json:object()
                let $put := (
                    map:put($person-obj, 'count', xs:int($person/@count)),
                    map:put($person-obj, 'value', xs:string($person))
                )
                return ( json:array-push($people-array, $person-obj) )
            return ( map:put($entities-obj, "people", $people-array) )
        return ( map:put($enrich-object, 'entities', $entities-obj) )

    let $concepts :=
        let $concepts-array := json:array()
        let $push :=
            for $concept in $data/concepts/concept
            let $concept-obj := json:object()
            let $matches-array := json:array()
            let $push :=
                for $match in $concept/concept-match
                let $match-obj := json:object()
                let $put := (
                    map:put($match-obj, 'score', xs:double($match/@score)),
                    map:put($match-obj, 'value', xs:string($match))
                )
                return ( json:array-push($matches-array, $match-obj) )
            let $puts := (
                map:put($concept-obj, 'label', xs:string($concept/@label)),
                map:put($concept-obj, 'score', xs:double($concept/@score)),
                map:put($concept-obj, 'matches', $matches-array)
            )
            return ( json:array-push($concepts-array, $concept-obj) )
        return ( map:put($enrich-object, 'concepts', $concepts-array) )
    let $text :=
        let $value := xdmp:quote($data/text/node())
        return ( map:put($enrich-object, 'text', $value) )

    let $related :=
        let $related-array := json:array()
        let $push :=
            for $match in $data/related/match
            let $match-obj := json:object()
            let $puts := (
                map:put($match-obj, "url", xs:string($match/@url)),
                map:put($match-obj, "score", xs:double($match/@score)),
                map:put($match-obj, "title", xs:string($match/@title))
            )
            return ( json:array-push($related-array, $match-obj))
        return ( map:put($enrich-object, 'related', $related-array) )

    return (
        xdmp:to-json($enrich-object)
    )
};

(:
    <enrich>
        <file> <some-xml-doc/> </file>
        <iterations>50</iterations>
        <threshold>0.05</threshold>
        <remove-stop-words>true</remove-stop-words>
        <remove-noise-words>true</remove-noise-words>
        <related-articles>false</related-articles>
        <id></id>
        <lang></lang>
        <return-text>true</return-text>
    </enrich>
:)
declare function tr:enrich( $data as element() ) {
    let $return-text as xs:boolean := fn:not($data/mle:enrich/return-text = "false")
    let $iterations as xs:int := xs:int( ($data/mle:enrich/iterations, 50)[1] )
    let $threshold as xs:double := xs:double( ($data/mle:enrich/threshold, 0.05)[1]  )
    let $remove-stop as xs:boolean := fn:not($data/mle:enrich/remove-stop-words = "false")
    let $remove-noise as xs:boolean := fn:not($data/mle:enrich/remove-noise-words = "false")
    let $related-articles as xs:boolean := fn:not($data/mle:enrich/related-articles = "false")
    let $lang := "eng"
    let $xml :=
        element {fn:node-name($data)} {
                $data/@*,
                $data/* except $data/mle:enrich
       }

    let $text as element(text) := <text xml:lang="{$lang}">{fn:normalize-space( fn:replace( fn:string-join($xml//text(), ' '), '&amp;|&nbsp;|\}|\{', ' ') )}</text>
    (: ' :)
    let $words := tr:normalize-words( $text, $remove-stop, $remove-noise, $lang )
    let $word-map := tr:textrank( tr:text-to-vertices( $words ), $iterations)
    let $terms := tr:find-best-terms( $word-map, $threshold  )
    let $phrases := tr:find-best-phrases($text, $word-map, $lang, $threshold )
    let $entities := tr:get-entities( $text, $lang )
    let $concepts := tr:match-concepts( $word-map, $terms, $lang )
    let $marked-text :=
        if ($return-text) then (
            tr:mark-text($text, $lang, $terms, $phrases, $entities, $concepts)
        ) else ()

    let $related :=
        if ($related-articles and 1 = 2) then (
            rf:related-articles($lang, $terms, $phrases, $concepts)
        ) else ()
    return (
        <mle:enrich>
            <mle:meta>
                {$terms}
                {$phrases}
                {$entities}
                {$concepts}
                {$related}
            </mle:meta>
            {$marked-text}
        </mle:enrich>
    )
};


(: Get top keywords :)
declare function tr:find-best-terms( $word-map, $threshold as xs:double ) {
    let $terms :=
        <terms>{
            for $word in map:keys( $word-map )
            let $inner-map := map:get( $word-map, $word )
            let $score := map:get($inner-map, 'score')
            let $count :=  map:get($inner-map, 'count')
            order by $score descending
            return <term score="{ $score }" count="{ $count }">{ $word }</term>
        }</terms>
    let $total-terms := fn:count( $terms/term )
    let $max-terms := xs:int( fn:floor( $total-terms * $threshold ) )
    let $max-terms := if ( $max-terms < 15 ) then ( 15 ) else ( $max-terms )
    let $terms := <terms>{ ($terms/term)[1 to $max-terms] }</terms>
    return $terms
};

(: Get top phrases :)
declare function tr:find-best-phrases( $text, $word-map, $lang, $threshold ) {
    let $phrases :=
        <phrases>{
            let $marked-up-text := tr:markup-phrases( $text, $word-map, $lang )
            for $phrase in fn:distinct-values( $marked-up-text//phrase/fn:lower-case( . ) )
            let $words := tr:normalize-words($phrase, fn:false(), fn:false(), $lang)
            let $score := fn:sum( for $word in $words return ( map:get(map:get($word-map, $word), 'score') ) )
            where fn:contains( $phrase, " " )
            order by $score descending
            return <phrase score="{$score}">{ $phrase }</phrase>
        }</phrases>

    let $total-phrases := fn:count( $phrases/phrase )
    let $max-phrases := xs:int( fn:floor( $total-phrases * $threshold ) )
    let $max-phrases := if ( $max-phrases < 10 ) then ( 10 ) else ( $max-phrases )
    let $phrases := <phrases>{ ($phrases/phrase)[1 to $max-phrases] }</phrases>
    return ( $phrases )
};

(: Get top concepts :)
declare function tr:match-concepts( $word-map, $terms, $lang ) {
  <concepts>{
        for $concept in cts:search(/concept, cts:reverse-query( $terms ) )
        let $concept-terms as xs:string* := $concept//cts:text
        let $matches :=
          for $term in $concept-terms
          let $map := map:get($word-map, $term)
          let $score := map:get($map,'score')
          where fn:exists($map)
          order by $score descending
          return (
            <concept-match score="{$score}">{$term}</concept-match>
          )
        let $match-count := fn:count( $matches )
        let $score := fn:sum($matches/@score)
        order by $score descending
        return
            <concept label="{ $concept/label/text() }" score="{$score}" matches="{ $match-count }">
               { $matches }
            </concept>
  }</concepts>
};

declare function tr:get-entities( $text, $lang ) {
    let $org-map := map:map()
    let $people-map := map:map()
    let $role-map := map:map()
    let $location-map := map:map()

    let $organizations :=
        for $org in fn:distinct-values(tr:markup-organizations( $text, $lang, $org-map )//entity)
        return <organization-entity count="{ map:get($org-map, $org) }">{$org}</organization-entity>
    let $people :=
        for $person in fn:distinct-values(tr:markup-people( $text, $lang, $people-map )//entity)
        return <person-entity count="{ map:get($people-map, $person) }">{$person}</person-entity>
    let $roles :=
        for $role in fn:distinct-values(tr:markup-roles( $text, $lang, $role-map )//entity)
        return <role-entity count="{ map:get($role-map, $role) }">{$role}</role-entity>
    let $locations :=
        for $location in fn:distinct-values(tr:markup-locations( $text, $lang, $location-map )//entity)
        return <location-entity count="{ map:get($location-map, $location) }">{$location}</location-entity>

    return <entities>{$organizations, $people, $roles, $locations}</entities>
};

declare function tr:markup-phrases( $text, $word-map, $lang ) {
    try {
        let $query := tr:build-word-query( map:keys($word-map), $lang )
        let $marked-up-text := cts:highlight( $text, $query, fn:concat( "{{{", fn:normalize-space( $cts:text ), "}}}" ) )
        let $marked-up-text := fn:replace( $marked-up-text, "<[^a-zA-Z]+", "<" )
        let $marked-up-text := fn:replace( $marked-up-text, "\}\}\}(\s|-)\{\{\{", "$1" )
        let $marked-up-text := fn:replace( $marked-up-text, "\{\{\{([^\}]+)\}\}\}", "&lt;phrase class='label label'&gt;$1&lt;/phrase&gt;" )
        let $marked-up-text := xdmp:unquote( fn:concat( "<p>", $marked-up-text, "</p>" ) )
        return $marked-up-text
    } catch ($e) {
        xdmp:trace('enrich', "Failed to mark phrases"),
        xdmp:trace('enirch-debug', $e),
        $text
    }
};

declare function tr:build-word-query( $words, $lang ) {
    let $options := (fn:concat( "lang=", $lang ), ("case-insensitive") )
    return
        cts:word-query($words, $options )
};

declare function tr:markup-locations( $text, $lang, $map) {
    let $locations :=
         cts:search(/location/name, $dir-query)
       
    let $query := cts:or-query( $locations )
    let $marked-up-text := cts:highlight( $text, $query, <entity type="location">{
        for $query  in $cts:queries
        let $text := fn:lower-case(cts:word-query-text($query))
        let $v := (map:get($map, $text), 0)[1]
        return (
            map:put($map, $text, $v + 1 ),
            fn:normalize-space( $text )
        )}</entity> )
    return $marked-up-text
};

declare function tr:markup-roles( $text, $lang, $map) {
    let $roles :=
        cts:search(/role/name, $dir-query)
    let $query := cts:or-query( $roles )
    let $marked-up-text := cts:highlight( $text, $query, <entity type="role">{
         for $query  in $cts:queries
         let $text := fn:lower-case(cts:word-query-text($query))
         let $v := (map:get($map, $text), 0)[1]
        return (
            map:put($map, $text, $v + 1 ),
            fn:normalize-space( $text )
        )}</entity> )
    return $marked-up-text
};

declare function tr:markup-organizations( $text, $lang, $map ) {
    let $organizations as xs:string* :=
        cts:search(/organization/name, $dir-query)
        (:cts:values(
            cts:path-reference("/organization/name", "collation=http://marklogic.com/collation/"),
            (),
            (),
            cts:directory-query('/enrich/', 'infinity')
        ) :)
    let $query := cts:or-query( $organizations )
    let $marked-up-text := cts:highlight( $text, $query, <entity type="org">{
         for $query  in $cts:queries
         let $text := fn:lower-case(cts:word-query-text($query))
         let $v := (map:get($map, $text), 0)[1]
        return (
            map:put($map, $text, $v + 1 ),
            fn:normalize-space( $text )
        )}</entity> )
    return $marked-up-text
};

declare function tr:markup-people( $text, $lang, $map ) {
    let $people :=
        cts:search(/person/name, $dir-query)
    let $query := cts:or-query( $people )
    let $marked-up-text := cts:highlight( $text, $query, <entity type="person">{
         for $query  in $cts:queries
         let $text := fn:lower-case(cts:word-query-text($query))
         let $v := (map:get($map, $text), 0)[1]
        return (
            map:put($map, $text, $v + 1 ),
            fn:normalize-space( $text )
        )}</entity> )
    return $marked-up-text
};

declare function tr:text-to-vertices( $words ) {
    if ( $words ) then (
        let $vertices := map:map()
        let $word-count := fn:count( $words )
        let $starting-score := xs:double( 1 div $word-count )
        let $ins := map:map()
        let $outs := map:map()
        let $counts := map:map()
        let $ins-and-outs :=
            for $word at $index in $words
            let $next := fn:subsequence($words, $index + 1, 1)
            where $word != $next
            return (
                map:put($counts, $word, (map:get($counts, $word),0)[1] + 1),
                map:put($ins, $next, (map:get($ins, $next), $word)),
                map:put($outs, $word, (map:get($outs, $word), $next ))
            )

        let $foo :=
            for $v in fn:distinct-values( $words )
            let $map := map:map()
            let $in := fn:distinct-values(map:get($ins, $v) )
            let $out := fn:distinct-values(map:get($outs, $v) )
            let $puts := (
                map:put($map, 'out', $out),
                map:put($map, 'out-count', fn:count( $out )),
                map:put($map, 'in', $in),
                map:put($map, 'in-count', fn:count( $in )),
                map:put($map, 'count', map:get($counts, $v) ),
                map:put($map, 'score', $starting-score)
            )
            return map:put( $vertices, $v, $map )
        return $vertices
    ) else ( map:map() )
};

declare function tr:remove-noise-words( $words, $lang as xs:string) {
    let $uri := "/enrich/" || $lang || "-noise-words.xml"
    let $map-xml as element(map:map)? := fn:doc($uri)//map:map
    let $map as map:map := if (fn:exists($map-xml)) then ( map:map( $map-xml ) ) else ( map:map() )
    for $word in $words
    where fn:not( map:contains( $map, $word ) )
    return
        $word
};

declare function tr:normalize-words( $text, $remove-stop-words as xs:boolean, $remove-noise-words as xs:boolean, $lang ) {
    let $words :=
        for $token in cts:tokenize( $text, $lang ) (: Limit to n words? :)
        return (
            typeswitch ( $token )
            case $token as cts:word return if ( fn:matches($token, '[0-9\.]+') ) then () else cts:stem(fn:lower-case( $token ), $lang)[1]
            default return ()
        )
    return (
        if ( $remove-noise-words ) then (
            tr:remove-noise-words( $words, $lang )
        ) else ( $words )
    )
};

declare function tr:textrank( $map, $iteration as xs:integer ) {
    let $convergence-threshold := 0.0001
    let $damping-factor := 0.85
    let $ers :=
        for $key in map:keys( $map )
        let $vertex := map:get( $map, $key )
        let $previous-score := map:get($vertex, 'score')
        let $outs := map:get($vertex, 'out')
        let $score :=
            xs:double(
                if ( fn:exists($outs) ) then (
                    (1 - $damping-factor) + ( $damping-factor *
                        fn:sum(
                            for $in-link in $outs
                            let $in-vertex := map:get( $map, $in-link )
                            let $in-pr := map:get($in-vertex, 'score')
                            let $in-link-out-count := map:get($in-vertex, 'in-count')
                            let $in-link-out-count := if ( $in-link-out-count = 0 ) then 1 else $in-link-out-count
                            return (
                                $in-pr div $in-link-out-count
                            )
                        )
                    )
                ) else (
                    (1 - $damping-factor) + ($damping-factor * $previous-score)
                )
            )
        let $er := fn:abs( $score - $previous-score )
        let $set := (
            map:put($vertex, 'score', $score),
            map:put($vertex, 'er', $er)
        )
        where $er != 0
        return $er
    let $convergence := fn:max( $ers )
    return
        if ( $convergence lt $convergence-threshold or ($iteration eq 1) ) then (
            $map
        ) else (
            tr:textrank( $map, $iteration - 1 )
        )
};

declare function tr:format-as-uri( $s as xs:string ) as xs:string {
    let $s := fn:replace( $s, "&amp;", "-" )
    let $s := xdmp:diacritic-less( $s )
    let $s := fn:lower-case( $s )
    let $s := fn:replace( $s, "[^0-9a-z\- ]", "" )
    let $s := fn:normalize-space( $s )
    let $s := fn:replace( $s, " ", "-" )
    let $s := fn:replace( $s, "[-]+", "-" )
    return $s
};


declare function tr:mark-text($text, $lang, $terms, $phrases, $entities, $concepts) as element(text) {
    let $options := (fn:concat( "lang=", $lang ), "case-insensitive", "punctuation-sensitive" )
    let $keyword-index-map := map:map()
    let $organization-index-map := map:map()
    let $person-index-map := map:map()
    let $role-index-map := map:map()
    let $location-index-map := map:map()

    let $items := (
        for $item as element() in
            (

                for $item as element() at $index in $entities/organization-entity
                let $term as xs:string := $item
                return <item length="{fn:string-length($term)}" type="organization" index="{$index}">{ $term }</item>,
                for $item as element() at $index in $entities/person-entity
                let $term as xs:string := $item
                return <item length="{fn:string-length($term)}" type="person" index="{$index}">{ $term }</item>,
                for $item as element() at $index in $entities/role-entity
                let $term as xs:string := $item
                return  <item length="{fn:string-length($term)}" type="role" index="{$index}">{ $term }</item>,
                for $item as element() at $index in $entities/location-entity
                let $term as xs:string := $item
                return <item length="{fn:string-length($term)}" type="location" index="{$index}">{ $term }</item>
            )
        order by xs:int($item/@length) descending
        return $item,
        for $item as element() at $index in $terms/term
        let $term as xs:string :=  $item
        let $length := fn:string-length($term)
        order by xs:int($length) descending
        return <item length="{$length}" type="keyword" index="{$index}">{ $term }</item>
    )

    let $marked-text := tr:mark-items($text, $lang, $items)

    return $marked-text
};

declare variable $word-query-options as xs:string* := (
    "case-insensitive",
    "diacritic-insensitive",
    "punctuation-insensitive",
    "whitespace-insensitive",
    "unwildcarded"
);

declare function tr:mark-items($node as node()*, $lang as xs:string, $items as element()*) {
    if ( fn:exists( $items ) ) then (
        let $item as element() := $items[1]
        let $word-query-options := ( $word-query-options , fn:concat( 'lang=', $lang ) )
        let $term as xs:string := $item
        let $marked-node :=
            cts:highlight(
                $node,
                cts:word-query($term, $word-query-options),
                if ( fn:empty($cts:node/ancestor-or-self::span) ) then (
                    <span class="ml-enrich-{$item/@type}-{$item/@index}">{$cts:text}</span>
                ) else ( $cts:text )
            )
        return (
            tr:mark-items($marked-node, $lang, fn:subsequence($items, 2))
        )
    ) else ( $node  )
};
