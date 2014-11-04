xquery version "1.0-ml";

declare variable $map as map:map external;

let $timestamp as xs:dateTime := fn:current-dateTime()
let $db-path as xs:string := map:get($map, 'FIELD:DB-PATH')
let $save-map as item()* := xdmp:document-insert($db-path, <field-map>{$map}</field-map>)
return (
    $timestamp
)