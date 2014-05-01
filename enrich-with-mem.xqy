xquery version "1.0-ml";

import module namespace mem = "http://maxdewpoint.blogspot.com/memory-operations" at "/memory/memory-operations.xqy";


declare function local:enrich($xmlIn){
  let $transaction-id := mem:copy($xmlIn) 
  let $markUPEntities := local:enrichEntities($transaction-id,$xmlIn)
  return mem:execute($transaction-id)
};

declare function local:enrichEntities($transaction-id, $xmlIn){
  for $entity in $entities/entity
    let $query := 
     cts:or-query((
        for $term in $entity/terms/term
        return cts:word-query($term, $queryOptions)
      ))
  return 
    cts:walk(
      $xmlIn, 
      $query,
        let $update := 
          mem:replace(
              $transaction-id,
              $cts:node/.., 
             (

              element {fn:local-name($cts:node/..)}
              {
                fn:substring($cts:node, 1, $cts:start - 1),
              element {"entity"} 
              {
                attribute entityId {$entity/@id},
                $cts:text
              },
              fn:substring($cts:node, $cts:start + fn:string-length($cts:text))

              }

              
             )
          )
        return $cts:text  
    )
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

