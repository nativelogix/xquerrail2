xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace model   = "http://xquerrail.com/model/base"  at "/_framework/base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/_framework/domain.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-DIRECTORY := "/test/program/";

declare variable $TEST-MODEL := 
  <model name="program" persistence="directory" label="Program" key="id" keyLabel="id" xmlns="http://xquerrail.com/domain">
    <directory>{$TEST-DIRECTORY}</directory>
    <attribute name="id" identity="true" type="identity" label="Id">
      <navigation searchable="true"></navigation>
    </attribute>
    <container name="container1" label="Container #1">
      <element name="field1" type="string" label="Field #1">
      </element> 
      <element name="field2" type="string" label="Field #2">
        <navigation exportable="false" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
      </element> 
    </container>
    <element name="field3" type="string" label="Field #3">
    </element> 
  </model>
;

declare variable $TEST-DOCUMENTS :=
(
  map:new((
    map:entry("container1.field1", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("field3", "123456")
  )),
  map:new((
    map:entry("container1.field1", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("field3", "654321")
  ))
);

declare %test:case function test-get-field-from-dotted-path-1() as item()*
{
  let $field := domain:get-field-from-dotted-path($TEST-MODEL, 'field3')
  return
  (
    assert:not-empty($field),
    assert:equal($field, 
      <element name="field3" type="string" label="Field #3" xmlns="http://xquerrail.com/domain"></element>
    )
  )
};

declare %test:case function test-get-field-from-dotted-path-2() as item()*
{
  let $field := domain:get-field-from-dotted-path($TEST-MODEL, 'container1.field1')
  return
  (
    assert:not-empty($field),
    assert:equal($field, 
      <element name="field1" type="string" label="Field #1" xmlns="http://xquerrail.com/domain"></element>
    )
  )
};

declare %test:case function test-get-field-value-from-dotted-path-1() as item()*
{
  let $instance := model:new($TEST-MODEL, $TEST-DOCUMENTS[1])
  let $value := domain:get-field-value-from-dotted-path($TEST-MODEL, 'field3', $instance)
  return
  (
    assert:equal($value/fn:string(.), '123456')
  )
};

declare %test:case function test-get-field-value-from-dotted-path-2() as item()*
{
  let $instance := model:new($TEST-MODEL, $TEST-DOCUMENTS[2])
  let $value := domain:get-field-value-from-dotted-path($TEST-MODEL, 'container1.field1', $instance)
  return
  (
    assert:equal($value/fn:string(.), 'oscar')
  )
};
