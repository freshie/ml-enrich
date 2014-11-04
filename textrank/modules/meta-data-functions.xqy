xquery version "1.0-ml";

module namespace mdf = "http://lds.org/code/enrich/meta-data-functions";

declare namespace enrich = "http://lds.org/code/shared/lds-edit/enrich";
declare namespace zip = "xdmp:zip";

declare function mdf:update-revision($db-path, $doc) {
    let $next-revision as xs:unsignedInt := get-newest-revision() + 1
    let $hash as xs:unsignedLong := mdf:hash-doc($doc)
    return (
        xdmp:document-set-property($db-path, <revision xmlns="http://lds.org/code/shared/lds-edit/enrich">{ $next-revision }</revision>),
        xdmp:document-set-property($db-path, <hash xmlns="http://lds.org/code/shared/lds-edit/enrich">{ $hash }</hash>)
    )
};

declare function mdf:hash-doc($doc as element()) as xs:unsignedLong {
    let $quoted as xs:string := xdmp:quote($doc)
    let $hash as xs:unsignedLong := xdmp:hash64( $quoted )
    return $hash
};

declare function mdf:get-newest-revision() as xs:unsignedInt {
    (
        cts:element-values(xs:QName('enrich:revision'), (), ("any","descending", "limit=1"),
            cts:directory-query('/enrich/content/meta/', 'infinity')
        ),
        0
    )[1]
};

declare function mdf:get-hash-map() as map:map {
   cts:element-values(xs:QName('enrich:hash'), (), ("map", "any"),
    cts:directory-query('/enrich/content/meta/', 'infinity')
   )
};

declare function mdf:get-uris-by-hash($hashes as xs:string*) as xs:string* {
    cts:uris("/", ("any"),
        cts:and-query((
               cts:directory-query('/enrich/content/meta/', 'infinity'),
               cts:properties-query( cts:element-value-query(xs:QName('enrich:hash'), $hashes, 'exact') )
        ))
    )
};

declare function mdf:get-hash($uri as xs:string) as xs:string {
    xdmp:document-get-properties($uri, xs:QName('enrich:hash'))
};

declare function mdf:build-update-zip($site-map as map:map?) as binary()? {
    let $hash-map as map:map :=  mdf:get-hash-map()

    let $delete-map as map:map := $site-map - $hash-map
    let $insert-map as map:map := $hash-map - $site-map

    let $uris := mdf:get-uris-by-hash( map:keys($insert-map) )

    let $docs := fn:doc($uris)

    let $manifest-map := map:map()

    let $delete-hashes := map:put($manifest-map, 'deletes', map:keys($delete-map))

    let $hmap := map:map()
    let $rmap := map:map()

    let $parts as element(zip:part)* :=
        for $doc in $docs
        let $db-path :=  xdmp:node-uri($doc)
        let $path := xdmp:diacritic-less(fn:substring($db-path, 2))

        let $hash as xs:string := xdmp:document-get-properties($db-path, xs:QName('enrich:hash'))
        let $revision as xs:string := xdmp:document-get-properties($db-path, xs:QName('enrich:revision'))

        let $puts := (
            map:put($hmap, $path, $hash),
            map:put($rmap, $path, $revision)
        )
        return (
            <part xmlns="xdmp:zip" >{ $path }</part>
        )

    let $zip-manifest as node() :=
        <parts xmlns="xdmp:zip">
            <part>ZIP-INFO/manifest-map.xml</part>
            { $parts }
        </parts>

    let $put as empty-sequence() := map:put($manifest-map, 'hashes', $hmap)
    let $put as empty-sequence() := map:put($manifest-map, 'revisions', $rmap)

    let $manifest-xml as element(manifest-map) := <manifest-map>{$manifest-map}</manifest-map>

    let $zip as binary() := xdmp:zip-create($zip-manifest, ($manifest-xml, $docs) )
    return (
        $zip
    )

};