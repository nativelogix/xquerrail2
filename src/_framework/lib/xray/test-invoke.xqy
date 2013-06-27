xquery version "1.0-ml";
import module namespace xray="http://github.com/robwhitby/xray" at "src/xray.xqy";

declare variable $action as xs:string  := xdmp:get-request-field("action");
declare variable $batchid as xs:string := xdmp:get-request-field("batchid");
declare variable $tests as xs:string   := xdmp:get-request-field("test");

xray:invoke-batch($batchid,$modules,$tests)
