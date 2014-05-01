let $entities :=
<entities>
  <entity markup="company">MarkLogic</entity>
</entities>

let $x :=  <p>MarkLogic Server is an enterprise-class
  database specifically built for content.</p>

for $entity in $entities/entity
return 
  cts:highlight(
    $x, 
    $entity, 
    element {$entity/@markup} {$cts:text})