declare function local:enrich($xmlIn as element()){
  let $entityEnrich := local:entityEnrich($xmlIn)
  
  let $pronounEnrich := local:pronounEnrich($entityEnrich)
  return $pronounEnrich
};

declare function local:pronounEnrichPersons($xmlIn as element(), $person as element()){
  let $query := 
          cts:near-query(
          (
            cts:and-query((
              cts:or-query((
                for $pronoun in $personalPronouns/thirdPersonSingular/pronoun
                return cts:word-query($pronoun, ($PronounQueryOptions) ) 
              )),
              for $term in $person/terms/term
              return 
              cts:word-query($term, $queryOptions)
           ))
          ),
          10)
  return     
  cts:highlight(
      $xmlIn, 
      $query,
      if (fn:lower-case($cts:text) eq $personalPronouns//pronoun/xs:string(.))
      then 
        element {"entity"}
        {
          attribute entityIds {fn:string-join($person/@id,",")},
          attribute debugQuery {$cts:queries}, 
          $cts:text
         }
       else ($cts:text)
     )
};

declare function local:pronounEnrich($xmlIn as element()){
  let $entiyId := fn:distinct-values($xmlIn//entity/@entityIds/fn:tokenize(., ','))
  let $persons := $entities/entity[@type eq 'person' and @id eq $entiyId]
  return fn:fold-left(local:pronounEnrichPersons(?, ?), $xmlIn, $persons)
};

declare function local:entityEnrich($xmlIn as element()){
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
        attribute entityIds {fn:string-join($entitiesThatMatch/@id,",")},
        (:attribute debugQuery {$cts:queries},:) 
        $cts:text
       }
     )
  return $xmlNew
};

declare variable $PronounQueryOptions := ("case-insensitive", "punctuation-insensitive", "whitespace-insensitive", "unstemmed", "lang=eng");

declare variable $queryOptions := ("case-insensitive", "punctuation-insensitive", "whitespace-insensitive", "stemmed", "lang=eng");

declare variable $personalPronouns :=
<pronouns>
  <firstPersonSingular>
    <pronoun>I</pronoun>
    <pronoun>me</pronoun>
    <pronoun>my</pronoun>
    <pronoun>mine</pronoun>
  </firstPersonSingular>
  <secondPersonSingular>
    <pronoun>you</pronoun> 
    <pronoun>your</pronoun>
    <pronoun>yours</pronoun>
  </secondPersonSingular>
  <thirdPersonSingular>
     <pronoun>he</pronoun>
     <pronoun>she</pronoun>
     <pronoun>it</pronoun>
     <pronoun>him</pronoun>
     <pronoun>her</pronoun>
     <pronoun>his</pronoun>
     <pronoun>hers</pronoun>
     <pronoun>its</pronoun>
  </thirdPersonSingular>
  <firstPersonPlural>
    <pronoun>we</pronoun>
    <pronoun>us</pronoun>
    <pronoun>our</pronoun>
    <pronoun>ours</pronoun>
  </firstPersonPlural>
  <secondPersonPlural>
   <pronoun>you</pronoun>
   <pronoun>your</pronoun>
   <pronoun>yours</pronoun>
  </secondPersonPlural>
  <thirdPersonPlural>
    <pronoun>they</pronoun>
    <pronoun>them</pronoun>
    <pronoun>their</pronoun>
    <pronoun>theirs</pronoun>
   </thirdPersonPlural>
</pronouns>;

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
  <entity type="person" id="6" name="Tyler">
   <terms>
     <term>tyler replogle</term>
   </terms>
  </entity>
   <entity type="person" id="3" name="Tyler Replogle">
   <terms>
     <term>tyler replogle</term>
   </terms>
  </entity>
  <entity type="object" id="4" name="Car">
   <terms>
     <term>Car</term>
   </terms>
  </entity>
  <entity type="action" id="5" name="ran">
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
  <p>Tyler Jay Replogle is a Marklogic devloper</p>
  <p>Tyler Replogle has two cars</p>
  <p>Tyler likes to run</p>
  <p>He liks to run</p>
  </xml>

return 
 local:enrich($xml)
