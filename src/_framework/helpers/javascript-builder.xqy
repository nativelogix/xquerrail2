xquery version "1.0-ml";

(:~
: Javascript Helper library
: Uses simple construct to build objects of json objects
~:)
module  namespace j = "http://www.xquerrail-framework.com/helper/javascript-builder";

(:~Helper functions for json ~:)
(:~
: Converts dateTime to epoch date
~:)
declare %private function j:dateTime-to-epoch($dateTime as xs:dateTime)
{
xs:unsignedLong(
($dateTime - xs:dateTime('1970-01-01T00:00:00'))
div xs:dayTimeDuration('PT1S') )
};

(:~
:  Converts date to epoch date
~:)
declare %private function j:date-to-epoch($date as xs:date)
{
xs:unsignedLong(
(fn:dateTime($date,xs:time("00:00:00")) - xs:dateTime('1970-01-01T00:00:00'))
div xs:dayTimeDuration('PT1S') )
};

declare function j:date($date as xs:date) {
j:literal("new Date(" || j:date-to-epoch($date) ||")")
};

declare function j:dateTime($dateTime as xs:dateTime) {
j:literal("new Date(" || j:dateTime-to-epoch($dateTime) || ")")
};
declare function j:literal($value as item()) {
json:unquotedString($value)
}; 
(:~
: Function automatically generates json string
~:)
declare function j:json($value as item()) {
if($value instance of json:object or $value instance of json:array)
then xdmp:to-json($value)
else xdmp:to-json(j:entry("value",$value))
};

(:~
: Builds a json object
~:)
declare function j:object($values as item()*) {
let $obj := json:object()
return (
for $value in $values 
return 
if($value instance of json:object or $value instance of json:array)
then xdmp:set($obj,$obj + $value)
else fn:error(xs:QName("NON-JSON-TYPE"),"The type you provided is not json"),
$obj
)
};
(:~
: Builds an array
~:)
declare function j:array($values as item()*) {
let $array := json:array()
return (
for $value in $values 
return
json:array-push($array,$value),
$array
)
};
(:~
: A entry represents a key value structure
~:)
declare function j:entry($key as xs:string,$value as item()*) {
let $entry  := json:object()
return (
map:put($entry,$key,$value),
$entry
)
};
declare function j:keyvalue($key as xs:string,$value as xs:anyAtomicType) {
j:entry($key,$value)
};
(:~
: Short Hand Notation for j:entry
~:)
declare function j:e($key,$value) {j:entry($key,$value)};
(:~
: Short Hand Notation for j:keyvalue
~:)
declare function j:kv($key,$value)  {j:keyvalue($key,$value)};
(:~
: Short Hand Notation for j:object
~:)
declare function j:o($values) {j:object($values)};
(:~
: Short Hand Notation for j:json
~:)
declare function j:j($json) {j:json($json)};
(:~
: Short Hand Notation for j:array
~:)
declare function j:a($values) {j:array($values)};
(:~
: Short hand notation for j:literal
~:)
declare function j:l($value) {j:literal($value)};
(:~
: Short hand notation for j:datTime
~:)
declare function j:dtm($value as xs:dateTime)  {j:dateTime($value)};
(:~
: Short hand notation for j:date
~:)
declare function j:dt($value as xs:date) {j:date($value)};


