xquery version "1.0-ml";

import module namespace tr = "https://github.com/freshie/ml-enrich/text-rank" at "/modules/textrank.xqy";
import module namespace util = "https://github.com/freshie/ml-enrich/utility" at "/modules/utility.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";


let $payload := xdmp:get-request-body('xml')

let $data := tr:enrich( $payload )

return (
    xdmp:set-response-content-type("text/xml; charset=utf-8"),
    $data
    )
