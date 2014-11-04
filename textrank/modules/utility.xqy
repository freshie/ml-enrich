xquery version "1.0-ml";

module namespace util = "https://github.com/freshie/ml-enrich/utility";

declare function util:stripNamespaces($xml as item()*) as item()* {
    util:renameSpace($xml, "")
};

declare function util:renameSpace($xml as item()*, $ns as xs:string) as item()* {
	for $n as item() in $xml
	return
	    typeswitch ($n)
	    case element() return element {fn:QName($ns, fn:local-name($n))} { $n/@*, util:renameSpace($n/node(), $ns)}
	    default return ( $n )
};

declare function util:get-url-parts($full-url as xs:string) as element(url-parts) {
    let $protocol as xs:string? := fn:replace(fn:substring-before($full-url, '//'), ':', '')
    let $hash as xs:string? := 
        if (fn:matches($full-url, '^[^#]*(#.*)$')) then (
            fn:replace($full-url, '^[^#]*(#.*)$', '$1')
        ) else ()
    let $params as xs:string? := 
        if (fn:matches($full-url, '^[^?#]*(\?[^#]*)(#.*)?$')) then (
          fn:replace($full-url, '^[^?#]*(\?[^#]*)(#.*)?$', '$1')
        ) else ()
    let $domain as xs:string? :=
        if ($protocol != "") then (
            fn:replace($full-url, '^.*//([^/#?]+)[/?#]?.*$', '$1')
        ) else if ( fn:starts-with($full-url, '/') ) then (
            ""
        ) else (
            fn:replace($full-url, '^([^/?#]+).*$', '$1')
        )
    let $cleaned-url as xs:string? :=
        if ($params != "") then (
            fn:substring-before($full-url, '?')
        ) else if ($hash != "") then (
            fn:substring-before($full-url, '#')
        ) else ( $full-url )
         
    let $uri as xs:string? :=
        if ($domain != '') then (
            fn:substring-after($cleaned-url, $domain)
        ) else (
            $cleaned-url
        )
    let $context as xs:string? := fn:replace($uri, '/([^/]+)[/]?.*', '$1')
    return  
      <url-parts url="{$full-url}">
        <protocol>{ $protocol }</protocol>
        <domain>{ $domain[. != $full-url] }</domain>
        <uri>{ $uri }</uri>
        <context>{ $context }</context>
        <params>{ $params }</params>
        <hash>{ $hash }</hash>
      </url-parts>
};