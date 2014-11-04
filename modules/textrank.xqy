xquery version "1.0-ml";

module namespace tr = "https://github.com/freshie/ml-enrich/text-rank";

import module namespace rf = "https://github.com/freshie/ml-enrich/related" at "/modules/related.xqy";

declare namespace mle = "https://github.com/freshie/ml-enrich";

declare variable $dir as xs:string := "/enrich/configuration/";
declare variable $dir-query as cts:query := cts:directory-query($dir, 'infinity');

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
                $data/* except ($data/mle:enrich,$data/mle:meta)
       }

    let $text := <taggedDocument xml:lang="{$lang}">{$xml}</taggedDocument>

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
        if ($related-articles) then (
            rf:related($lang, $terms, $phrases, $concepts)
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
            <orignalDocument>{$data}</orignalDocument>
        </mle:enrich>
    )
};


(: Get top keywords :)
declare function tr:find-best-terms( $word-map, $threshold as xs:double ) {
    let $terms :=
        <mle:terms>{
            for $word in map:keys( $word-map )
            let $inner-map := map:get( $word-map, $word )
            let $score := map:get($inner-map, 'score')
            let $count :=  map:get($inner-map, 'count')
            order by $score descending
            return <mle:term score="{ $score }" count="{ $count }">{ $word }</mle:term>
        }</mle:terms>
    let $total-terms := fn:count( $terms/term )
    let $max-terms := xs:int( fn:floor( $total-terms * $threshold ) )
    let $max-terms := if ( $max-terms < 15 ) then ( 15 ) else ( $max-terms )
    let $terms := <mle:terms>{ ($terms/mle:term)[1 to $max-terms] }</mle:terms>
    return $terms
};

(: Get top phrases :)
declare function tr:find-best-phrases( $text, $word-map, $lang, $threshold ) {
    let $phrases :=
        <mle:phrases>{
            let $marked-up-text := tr:markup-phrases( $text, $word-map, $lang )
            for $phrase in fn:distinct-values( $marked-up-text//phrase/fn:lower-case( . ) )
            let $words := tr:normalize-words($phrase, fn:false(), fn:false(), $lang)
            let $score := fn:sum( for $word in $words return ( map:get(map:get($word-map, $word), 'score') ) )
            where fn:contains( $phrase, " " )
            order by $score descending
            return <mle:phrase score="{$score}">{ $phrase }</mle:phrase>
        }</mle:phrases>

    let $total-phrases := fn:count( $phrases/mle:phrase )
    let $max-phrases := xs:int( fn:floor( $total-phrases * $threshold ) )
    let $max-phrases := if ( $max-phrases < 10 ) then ( 10 ) else ( $max-phrases )
    let $phrases := <mle:phrases>{ ($phrases/mle:phrase)[1 to $max-phrases] }</mle:phrases>
    return ( $phrases )
};

(: Get top concepts :)
declare function tr:match-concepts( $word-map, $terms, $lang ) {
  <mle:concepts>{
        for $concept in cts:search(/concept, cts:reverse-query( $terms ) )
        let $concept-terms as xs:string* := $concept//cts:text
        let $matches :=
          for $term in $concept-terms
          let $map := map:get($word-map, $term)
          let $score := map:get($map,'score')
          where fn:exists($map)
          order by $score descending
          return (
            <mle:concept-match score="{$score}">{$term}</mle:concept-match>
          )
        let $match-count := fn:count( $matches )
        let $score := fn:sum($matches/@score)
        order by $score descending
        return
            <mle:concept label="{ $concept/label/text() }" score="{$score}" matches="{ $match-count }">
               { $matches }
            </mle:concept>
  }</mle:concepts>
};

declare function tr:get-entities( $text, $lang ) {
    let $org-map := map:map()
    let $people-map := map:map()
    let $role-map := map:map()
    let $location-map := map:map()

    let $organizations :=
        for $org in fn:distinct-values(tr:markup-organizations( $text, $lang, $org-map )//entity)
        return <mle:organization-entity count="{ map:get($org-map, $org) }">{$org}</mle:organization-entity>
    let $people :=
        for $person in fn:distinct-values(tr:markup-people( $text, $lang, $people-map )//entity)
        return <mle:person-entity count="{ map:get($people-map, $person) }">{$person}</mle:person-entity>
    let $roles :=
        for $role in fn:distinct-values(tr:markup-roles( $text, $lang, $role-map )//entity)
        return <mle:role-entity count="{ map:get($role-map, $role) }">{$role}</mle:role-entity>
    let $locations :=
        for $location in fn:distinct-values(tr:markup-locations( $text, $lang, $location-map )//entity)
        return <mle:location-entity count="{ map:get($location-map, $location) }">{$location}</mle:location-entity>

    return <mle:entities>{$organizations, $people, $roles, $locations}</mle:entities>
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
         cts:search(/locations/location/name, $dir-query)
       
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
        cts:search(/roles/role/name, $dir-query)
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
        cts:search(/organizations/organization/name, $dir-query)
       
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
        cts:search(/people/person/name, $dir-query)
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
                map:put($map, 'in-count', fn:count( $in ) + 1),
                map:put($map, 'count', map:get($counts, $v) ),
                map:put($map, 'score', $starting-score)
            )
            return map:put( $vertices, $v, $map )
        return $vertices
    ) else ( map:map() )
};

declare function tr:remove-noise-words( $words, $lang as xs:string) {
    let $uri := $dir || $lang || "/noise-words.xml"
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
                            return 
                                $in-pr div $in-link-out-count
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

declare function tr:mark-text($text, $lang, $terms, $phrases, $entities, $concepts) as element(taggedDocument) {
    let $options := (fn:concat( "lang=", $lang ), "case-insensitive", "punctuation-sensitive" )
    let $keyword-index-map := map:map()
    let $organization-index-map := map:map()
    let $person-index-map := map:map()
    let $role-index-map := map:map()
    let $location-index-map := map:map()

    let $items := (
        for $item as element() in
            (

                for $item as element() at $index in $entities/mle:organization-entity
                let $term as xs:string := $item
                return <item length="{fn:string-length($term)}" type="organization" index="{$index}">{ $term }</item>,
                for $item as element() at $index in $entities/mle:person-entity
                let $term as xs:string := $item
                return <item length="{fn:string-length($term)}" type="person" index="{$index}">{ $term }</item>,
                for $item as element() at $index in $entities/mle:role-entity
                let $term as xs:string := $item
                return  <item length="{fn:string-length($term)}" type="role" index="{$index}">{ $term }</item>,
                for $item as element() at $index in $entities/mle:location-entity
                let $term as xs:string := $item
                return <item length="{fn:string-length($term)}" type="location" index="{$index}">{ $term }</item>
            )
        order by xs:int($item/@length) descending
        return $item,
        for $item as element() at $index in $terms/mle:term
        let $term as xs:string :=  $item
        let $length := fn:string-length($term)
        order by xs:int($length) descending
        return <item length="{$length}" type="keyword" index="{$index}">{ $term }</item>
    )

    let $marked-text := 
        fn:fold-left(
           function($result, $item) {  tr:mark-items($result, $item, $lang) },
           $text,
           $items
        )
    return $marked-text
};

declare variable $word-query-options as xs:string* := (
    "case-insensitive",
    "diacritic-insensitive",
    "punctuation-insensitive",
    "whitespace-insensitive",
    "unwildcarded"
);

declare function tr:mark-items($node as node()*, $item as element(), $lang as xs:string) {
    let $word-query-options := ( $word-query-options , 'lang=' || $lang  )
    let $term as xs:string := $item
    let $marked-node :=
        cts:highlight(
            $node,
            cts:word-query($term, $word-query-options),
            if ( fn:empty($cts:node/ancestor-or-self::enitity) ) then (
                <enitity type="{$item/@type}">{$cts:text}</enitity>
            ) else ( $cts:text )
        )
    return $marked-node
};