xquery version "1.0-ml";

module namespace fmap = "http://lds.org/code/shared/field-map";

(:
    Returns a field map for the passed in db-uri, will create one if it doesn't exists
    @param $db-uri = database path to read/create field map
    @return map:map
:)
declare function fmap:get-map($db-uri) as map:map {
    let $map as map:map? := fmap:get-server-field($db-uri)
    let $db-timestamp as xs:dateTime := fmap:get-uri-timestamp($db-uri)
    let $is-valid as xs:boolean := fn:exists($map) and map:get($map, 'FIELD:TIMESTAMP') >= $db-timestamp
    return (
        if ($is-valid) then (
            $map
        ) else (
            let $map-xml as element(map:map)? := fn:doc($db-uri)//map:map
            let $map as map:map := if (fn:exists($map-xml)) then ( map:map( $map-xml ) ) else ( map:map() )
            let $put-FIELD-keys as empty-sequence() := ( map:put($map, 'FIELD:DB-PATH', $db-uri), map:put($map, 'FIELD:TIMESTAMP', $db-timestamp) )
            let $save as empty-sequence() := fmap:save-map($map)
            return (
                $map
            )
        )
    )
};

(: wrapper around map:get, not really needed but felt it completed the library :)
declare function fmap:get($map as map:map, $key as xs:string) as item()* {
    map:get($map, $key)
};

(: wrapper around map:put, does a normal map:put and updates the server-field with the new map :)
declare function fmap:put($map as map:map, $key as xs:string, $value as item()*) as empty-sequence() {
   let $put as empty-sequence() := map:put($map, $key, $value)
   let $field-save := fmap:save-map($map)
   return ()
};

(:
    Saves the map to the database
    Needs amp:
        http://marklogic.com/xdmp/privileges/xdmp-spawn
    @param $map = map to save
    @return empty-sequence
:)
declare function fmap:save-map($map as map:map) as empty-sequence() {
    let $xquery as xs:string := './save-field-maps.xqy'
    let $vars as item()* := (
        xs:QName('map'), $map
    )
    let $options :=
        <options xmlns="xdmp:eval">
        </options>

    let $save := xdmp:spawn($xquery, $vars, $options)

    let $db-path as xs:string := map:get($map, 'FIELD:DB-PATH')
    let $update-time as empty-sequence() := map:put($map, 'FIELD:TIMESTAMP', fn:current-dateTime())
    let $set-field as item()* := fmap:set-server-field($db-path, $map)
    return ()
};

(:
    Wrapper around xdmp:set-server-field
    Needs amp:
        http://marklogic.com/xdmp/privileges/xdmp-set-server-field
    @param $key = Field key
    @param $value = Field value
    @return field value
:)
declare function fmap:set-server-field($key as xs:string, $value as item()*) as item()* {
    xdmp:set-server-field($key, $value)
};

(:
    Wrapper around xdmp:get-server-field
    Needs amp:
        http://marklogic.com/xdmp/privileges/xdmp-get-server-field
    @param $key = Field key
    @return field value
:)
declare function fmap:get-server-field($key as xs:string) as item()* {
    xdmp:get-server-field($key)
};

(:
    Attempts to get the last modified dateTime for that uri.
    @param $db-uri = database uri
    @return xs:dateTime()
:)
declare function fmap:get-uri-timestamp($db-uri) as xs:dateTime {
    try {
        xdmp:document-get-properties($db-uri, xs:QName('prop:last-modified'))
    } catch ($e) {
        fn:current-dateTime()
    }
};

(:
    Map Extend, much like a jquery extend
    First map is updated in place with all the of the other maps values.
    @param $map = sequence of maps to extend/merge into map1
    @return map1
:)
declare function fmap:extend($maps as map:map*) as map:map {
    let $map1 as map:map := $maps[1]
    let $extend :=
        for $map in fn:subsequence($maps, 2)
        for $key in map:keys($map)
        return (
            map:put($map1, $key, map:get($map, $key))
        )
    return $map1
};