declare function local:enrich($xmlIn){
  local:enrich($xmlIn, 1)
};

declare function local:enrich($xmlIn, $positionIn){
   let $entity := $entities/entity[$positionIn]
   let $query := 
     cts:or-query((
        for $term in $entity/terms/term
        return cts:word-query($term, $queryOptions)
      ))
   let $xmlNew :=
     cts:highlight(
      $xmlIn, 
      $query,
        element {"entity"} 
        {
          attribute entityId {$entity/@id},
          $cts:text
         }
     )
   (: helps for debuggin, this will show the query for each entity 
   let $xmlNew := 
     <xml>{$xmlNew/element()} <query id="{$entity/@id}">{$query}</query></xml> :)
   let $positionNew := $positionIn + 1
   return 
     if ($positionNew le fn:count($entities/entity))
     then 
       local:enrich($xmlNew, $positionNew)
     else $xmlNew
};

declare variable $queryOptions := ("case-insensitive", "punctuation-insensitive", "whitespace-insensitive", "stemmed", "lang=eng");

declare variable $entities :=
<entities>
  <entity type="company" id="1" name="MarkLogic">
   <terms>
     <term>markLogic</term>
   </terms>
  </entity>
  <entity type="company" id="2" name="MongoDB">
   <terms>
     <term>mongodb</term>
   </terms>
  </entity>
   <entity type="person" id="3" name="Tyler Replogle">
   <terms>
     <term>tyler</term>
     <term>tyler replogle</term>
     <term>replogle</term>
     <term>rep</term>
   </terms>
  </entity>
  <entity markup="object" id="4" name="Car">
   <terms>
     <term>Car</term>
   </terms>
  </entity>
  <entity markup="action" id="5" name="ran">
   <terms>
     <term>ran</term>
   </terms>
  </entity>
</entities>;



let $xml :=  
  <xml>
  <p>MarkLogic Server is an enterprise-class
  database specifically built for content.</p>
  <p>MongoDB is a cross-platform document-oriented database system.</p>
  <p>Tyler Replogle is a Marklogic devloper</p>
  <p>Tyler Replogle has two cars</p>
  <p>Tyler likes to run</p>
  </xml>

return 
 local:enrich($xml)

