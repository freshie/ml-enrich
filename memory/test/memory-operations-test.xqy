xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace mem = "http://maxdewpoint.blogspot.com/memory-operations" at "/memory-operations.xqy";

declare variable $test-xml := <html>
								<head>
									<title>This is a title</title>
								</head>
								<!-- old comment -->
								<body>
									<div id="div1">
										<p class="p1"><!-- old comment -->This is a paragraph.</p>
										<p class="p2">This is a paragraph.</p>
										<p class="p3">This is a paragraph.</p>
										<p class="p4">This is a paragraph.</p>
										<p class="p5">This is a paragraph.</p>
									</div>
									<div id="div2">
										<p class="p1">This is a paragraph.</p>
										<p class="p2">This is a paragraph.</p>
										<p class="p3">This is a paragraph.<!-- old comment --></p>
										<p class="p4">This is a paragraph.</p>
										<p class="p5">This is a paragraph.</p>
									</div>
								</body>
							</html>;



declare %test:case function insert-child-into-root-attribute()
as item()*
{
	let $new-xml := mem:insert-child(
						$test-xml,
						attribute test {"testing"}
					)
	return assert:equal(fn:string($new-xml/@test), 'testing')	
};

declare %test:case function insert-child-into-many-items-attribute()
as item()*
{
	let $new-xml := mem:insert-child(
						($test-xml,$test-xml/body/div[@id eq "div1"],
						$test-xml/body/div/p),
						attribute test {"testing"}
					)
	for $i in ($new-xml,$new-xml/body/div[@id eq "div1"],
						$new-xml/body/div/p)
	return assert:equal(fn:string($i/@test), 'testing')	
};

declare %test:case function insert-child-into-root-element()
as item()*
{
	let $new-xml := mem:insert-child(
						$test-xml,
						element test {"testing"}
					)
	return assert:equal(fn:string($new-xml/test), 'testing')	
};

declare  %test:case function insert-child-into-many-items-element()
as item()*
{
	let $new-xml := mem:insert-child(
						($test-xml,$test-xml/body/div[@id eq "div1"],
						$test-xml/body/div/p),
						element test {"testing"}
					)
	for $i in ($new-xml,$new-xml/body/div[@id eq "div1"],
						$new-xml/body/div/p)
	return assert:equal(fn:string($i/test), 'testing')	
};

declare %test:case function insert-before()
as item()*
{
	let $new-xml := mem:insert-before(
						$test-xml/body/div/p[@class eq "p3"],
						element p { attribute class {"testing"}}
					)
	return (
	   assert:equal(fn:count($new-xml/body/div/p[@class eq "p3"]), 2),
	   for $p at $pos in $new-xml/body/div/p[@class eq "p3"]
	   return (
		  assert:equal(fn:string(($p/preceding-sibling::node())[fn:last()]/@class), 'testing'),
		  assert:equal(fn:string($p/parent::node()/@id), fn:concat('div',$pos))
	   )
	)
};

declare %test:case function insert-before-and-insert-attribute()
as item()*
{
	let $new-xml := 
	           let $id := mem:copy($test-xml) 
			   return (
	               mem:insert-before($id,
						$test-xml/body/div/p[@class eq "p3"],
						element p { attribute class {"testing"}}
					),
					mem:insert-child($id, $test-xml/body/div/p[@class eq "p3"], attribute data-testing {"this-is-a-test"}),
					mem:execute($id)
				)
	return (
	   assert:equal(fn:count($new-xml/body/div/p[@class eq "p3"]), 2),
	   for $p at $pos in $new-xml/body/div/p[@class eq "p3"]
	   return (
		  assert:equal(fn:string(($p/preceding-sibling::node())[fn:last()]/@class), 'testing'),
		  assert:equal(fn:string($p/@data-testing), 'this-is-a-test'),
		  assert:equal(fn:string($p/parent::node()/@id), fn:concat('div',$pos))
	   )
	)
};

declare %test:case function insert-after()
as item()*
{
	let $new-xml := mem:insert-after(
						$test-xml/body/div/p[@class eq "p3"],
						element p { attribute class {"testing"}}
					)
	return (
	   assert:equal(fn:count($new-xml/body/div/p[@class eq "p3"]), 2),
	   for $p at $pos in $new-xml/body/div/p[@class eq "p3"]
	   return (
		  assert:equal(fn:string($p/following-sibling::node()[1]/@class), 'testing'),
		  assert:equal(fn:string($p/parent::node()/@id), fn:concat('div',$pos))
	   )
	)
};

declare %test:case function insert-after-and-insert-attribute()
as item()*
{
	let $new-xml := 
	           let $id := mem:copy($test-xml) 
			   return (
				    mem:insert-after($id,
						$test-xml/body/div/p[@class eq "p3"],
						element p { attribute class {"testing"}}
					),
					mem:insert-child($id, $test-xml/body/div/p[@class eq "p3"], attribute data-testing {"this-is-a-test"}),
					mem:execute($id)
				)
	return (
	   assert:equal(fn:count($new-xml/body/div/p[@class eq "p3"]), 2),
	   for $p at $pos in $new-xml/body/div/p[@class eq "p3"]
	   return (
		  assert:equal(fn:string($p/following-sibling::node()[1]/@class), 'testing'),
		  assert:equal(fn:string($p/@data-testing), 'this-is-a-test'),
		  assert:equal(fn:string($p/parent::node()/@id), fn:concat('div',$pos))
	   )
	)
};
declare %test:case function remove-items()
as item()*
{
   let $new-xml := mem:delete(
						$test-xml//comment()
					)
	return (assert:equal(fn:count($test-xml//comment()) gt 0, fn:true()),
			assert:equal(fn:count($new-xml//comment()), 0))
};

declare %test:case function replace-items()
as item()*
{
   let $new-xml := mem:replace(
						$test-xml//comment(),
						<!--this new comment-->
					)
	return (assert:equal(fn:count($new-xml//comment()), fn:count($test-xml//comment())),
			for $c in $new-xml//comment()
			return assert:equal(fn:string($c), 'this new comment'))
};

declare %test:case function replace-item-values()
as item()*
{
   let $new-xml := mem:replace-value(
						$test-xml//comment(),
						"this new comment"
					)
	return (assert:equal(fn:count($new-xml//comment()), fn:count($test-xml//comment())),
			for $c in $new-xml//comment()
			return assert:equal(fn:string($c), 'this new comment'))
};

declare %test:case function replace-attributes()
as item()*
{
   let $new-xml := mem:replace(
						$test-xml//p/@class,
						attribute class {"new-class"}
					)
	return (assert:equal(fn:count($new-xml//p/@class), fn:count($test-xml//p/@class)),
			for $c in $new-xml//p/@class
			return assert:equal(fn:string($c), 'new-class'))
};

declare %test:case function replace-value-attributes()
as item()*
{
   let $new-xml := mem:replace-value(
						$test-xml//p/@class,
						"new-class"
					)
	return (assert:equal(fn:count($new-xml//p/@class), fn:count($test-xml//p/@class)),
			for $c in $new-xml//p/@class
			return assert:equal(fn:string($c), 'new-class'))
};

declare %test:case function rename()
as item()*
{
  let $new-xml-blocks := mem:rename($test-xml//p,fn:QName("","block"))/body/div/block
  return (for $p at $pos in $test-xml/body/div/p
		  return assert:equal($p/(@*|node()), $new-xml-blocks[$pos]/(@*|node())))
};

declare %test:case function advanced-operation()
as item()*
{
  let $new-xml := 
				let $id := mem:copy($test-xml) 
				return
				(
				mem:replace($id,$test-xml/head/title,element title {"This is so awesome!"}),
				mem:insert-child($id,$test-xml/body/div/p,attribute data-info {"This is also awesome!"}),
				mem:execute($id)	
				)
				
  return (assert:equal(fn:string($new-xml/head/title), "This is so awesome!"),
			for $p in $new-xml/body/div/p
			return assert:equal(fn:string($p/@data-info), "This is also awesome!"))
};

declare %test:case function copy()
as item()*
{
  let $test-xml := document { $test-xml }/html
  let $new-xml := 
				let $id := mem:copy($test-xml) 
				return
				(
				mem:replace($id,$test-xml/head/title,element title {"This is so awesome!"}),
				mem:insert-child($id,$test-xml/body/div/p,attribute data-info {"This is also awesome!"}),
				mem:execute($id)	
				)
  return (assert:equal($new-xml instance of element(html), fn:true()),
			assert:equal(fn:string($new-xml/head/title), "This is so awesome!"),
			for $p in $new-xml/body/div/p
			return assert:equal(fn:string($p/@data-info), "This is also awesome!"))
};

declare %test:case function multiple-operations-on-one-node()
as item()*
{
  let $title := $test-xml/head/title
  let $new-xml := 
				let $id := mem:copy($title) 
				return
				(
				mem:rename($id,$title,fn:QName("","new-title")),
				mem:replace-value($id,$title,"This is so awesome!"),
				mem:execute($id)	
				)
  return (assert:equal($new-xml instance of element(new-title), fn:true()),
			assert:equal(fn:string($new-xml), "This is so awesome!"))
};

declare %test:case function transform-function-transaction()
as item()*
{
  let $title := $test-xml/head/title
  let $new-xml := 
				let $id := mem:copy($title) 
				return
				(
				mem:transform($id,$title,function($node as node()) as node()* {element new-title {"This is so awesome!"}}),
				mem:execute($id)	
				)
  return (assert:equal($new-xml instance of element(new-title), fn:true()),
			assert:equal(fn:string($new-xml), "This is so awesome!"))
};

declare %test:case function transform-function()
as item()*
{
  let $title := $test-xml/head/title
  let $new-xml :=  mem:transform($title,function($node as node()) as node()* {element new-title {"This is so awesome!"}})
  return assert:equal(fn:string($new-xml/head/new-title), "This is so awesome!")
};

declare %test:case function execute-section()
as item()*
{
  let $div1 := $test-xml//div[@id = "div1"]
  let $new-xml := 
				let $id := mem:copy($test-xml)[1]
				return
				(
				mem:insert-child($id,$div1,attribute class {"added-class"}),
				mem:replace($id,$div1,
				    let $copy := mem:execute-section($id, $div1)
				    for $i in (1 to 10)
				    let $cid := mem:copy($copy)
				    return 
				        (
				            mem:insert-child($cid,$copy,attribute data-position {$i}),
				            mem:execute($cid)
				        )
				),
				mem:execute($id)	
				)
  return (assert:equal(fn:count($new-xml//div[@id = "div1"]), 10),
            for $div at $pos in $new-xml//div[@id = "div1"]
			return (
			 assert:equal(fn:number($div/@data-position), $pos),
			 assert:equal(fn:string($div/@class), "added-class")
			)
		)
};

declare %test:case function throws-error-on-mixed-sources()
as item()*
{
  let $other-doc := <doc><p>my paragraph</p></doc>
  return
    assert:true(
      try {
        mem:replace(($test-xml,$other-doc)//p, <PARA/>)
      } catch mem:MIXEDSOURCES {
        fn:true()
      }
    )
};