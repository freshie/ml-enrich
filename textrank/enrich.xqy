xquery version "1.0-ml";

import module namespace tr = "https://github.com/freshie/ml-enrich/text-rank" at "/modules/textrank.xqy";
import module namespace util = "https://github.com/freshie/ml-enrich/utility" at "/modules/utility.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare option xdmp:output "method = html";

(: Content-Type header is used to specify what data format is being posted to the service :)
let $contentType := xdmp:get-request-header("Content-Type", "text/xml")
(: format request param to specify what data format is returned from service :)
let $format := xdmp:get-request-field("format", "xml")

let $payload :=
    if ( $contentType = "application/json" ) 
    then
        let $json-text as xs:string := xdmp:get-request-body('text')
        let $json-xml := util:strip-namespaces(json:transform-from-json($json-text))
        let $enrich-data :=
            element enrich {
                element file {
                    util:unquote($json-xml/file)
                },
                $json-xml/* except $json-xml/file
            }
        return
            $enrich-data
    else
        xdmp:get-request-body('xml')/enrich

let $data := tr:enrich( $payload )

return (
    if ($format = "json") then (
        xdmp:set-response-content-type("application/json"),
        tr:result-to-json($data)
    ) else (
        xdmp:set-response-content-type("text/xml; charset=utf-8"),
        $data
    )
)
