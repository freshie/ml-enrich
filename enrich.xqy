xquery version "1.0-ml";

import module namespace tr = "https://github.com/freshie/ml-enrich/text-rank" at "/modules/textrank.xqy";

let $payload := xdmp:get-request-body('xml')

let $data := tr:enrich( $payload )

return (
    xdmp:set-response-content-type("text/xml; charset=utf-8"),
    $data
    )
