declare function local:enrich($xmlIn, $entities, $positionIn){
   let $entity := $entities[$positionIn]
   let $xmlNew :=
   cts:highlight(
    $xmlIn, 
    $entity, 
    element {$entity/@markup} {$cts:text})
   let $positionNew := $positionIn + 1
   return 
     if ($positionNew le fn:count($entities))
     then 
       local:enrich($xmlNew, $entities, $positionNew)
     else $xmlNew
};

let $entities :=
<entities>
  <entity markup="company">MarkLogic</entity>
  <entity markup="company">MongoDB</entity>
</entities>

let $xml :=  
  <xml>
  <p>MarkLogic Server is an enterprise-class
  database specifically built for content.</p>
  <p>MongoDB is a cross-platform document-oriented database system.</p>
  </xml>

return 
 local:enrich($xml, $entities/entity, 1)

