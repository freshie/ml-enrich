declare function local:enrich($xmlIn){
  local:enrich($xmlIn, 1)
};

declare function local:enrich($xmlIn, $positionIn){
   let $entity := $entities/entity[$positionIn]
   let $xmlNew :=
     cts:highlight(
      $xmlIn, 
      cts:word-query($entity, $queryOptions),
      element {$entity/@markup || "-entity"} 
      {
        attribute entityId {$entity/@id},
        $cts:text
       }
     )
   let $positionNew := $positionIn + 1
   return 
     if ($positionNew le fn:count($entities/entity))
     then 
       local:enrich($xmlNew, $positionNew)
     else $xmlNew
};

declare variable $entities :=
<entities>
  <entity markup="company" id="1">MarkLogic</entity>
  <entity markup="company" id="2">MongoDB</entity>
  <entity markup="person" id="3">tyler replogle</entity>
  <entity markup="object" id="4">Car</entity>
  <entity markup="action" id="5">ran</entity>
</entities>;

declare variable $queryOptions := ("case-insensitive", "punctuation-insensitive", "whitespace-insensitive", "stemmed", "lang=eng");

let $xml :=  
  <xml>
  <p>MarkLogic Server is an enterprise-class
  database specifically built for content.</p>
  <p>MongoDB is a cross-platform document-oriented database system.</p>
  <p>Tyler Replogle is a Marklogic devloper</p>
  <p>Tyler Replogle has two cars</p>
  <p>He likes to run</p>
  </xml>

return 
 local:enrich($xml)

