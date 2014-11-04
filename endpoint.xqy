(:
    This was originally coded by Stewart Shelline 
    and then enhanced by  William Sawyer (https://github.com/williammsawyer). 
    So some of the concepts that they thought up are still part of this code. 
    It has since been recoded and anything that was specific to application it was made for has been removed. 
:)

xquery version "1.0-ml";

import module namespace tr = "https://github.com/freshie/ml-enrich/text-rank" at "/modules/textrank.xqy";

let $payload := xdmp:get-request-body('xml')

let $data := tr:enrich( $payload )

return (
    xdmp:set-response-content-type("text/xml; charset=utf-8"),
    $data
    )