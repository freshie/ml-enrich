declare function local:enrich($xmlIn){
  local:entityEnrich($xmlIn)
};

declare function local:entityEnrich($xmlIn){
   let $query := 
     cts:or-query((
        for $term in $entities/entity/terms/term
        return cts:word-query($term, $queryOptions)
      ))
   let $xmlNew :=
     cts:highlight(
      $xmlIn, 
      $query,
      element {"entity"} 
      {
        let $entitiesThatMatch :=
          for $query  in $cts:queries
          let $term := cts:word-query-text($query)
          return $entities/entity[terms/term/xs:string(.) eq $term]
        return 
        attribute entityId {fn:string-join($entitiesThatMatch/@id,"-")},
        (:attribute debugQuery {$cts:queries},:)
        $cts:text
       }
     )
  return $xmlNew
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
