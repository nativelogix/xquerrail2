xquery version "1.0-ml";

import module namespace request = "http://www.xquerrail-framework.com/request"
   at "/_framework/request.xqy";
   
import module namespace response = "http://www.xquerrail-framework.com/response"
   at "/_framework/response.xqy";
   
import module namespace model = "http://www.xquerrail-framework.com/model"
   at "/_framework/model.xqy";

import module namespace domain = "http://www.xquerrail-framework.com/domain"
   at "/_framework/domain.xqy";
   
import module namespace json = "http://marklogic.com/json" 
   at "/_framework/lib/mljson.xqy";

import module namespace js = "http://www.xquerrail-framework.com/helper/javascript"
   at "/_framework/helpers/javascript.xqy";

declare variable $response as map:map external;

response:initialize($response),
   let $model := 
      if($is-listable)
      then domain:get-domain-model($node/@type)
      else domain:get-domain-model(fn:local-name($node)) 
   return
     if($model) then 
 js:o((       
            js:pair("currentpage",$node/currentpage cast as xs:integer),
            js:pair("pagesize",$node/pagesize cast as xs:integer),
            js:pair("totalpages",$node/totalpages cast as xs:integer),
            js:pair("totalrecords",$node/totalrecords cast as xs:integer),
            js:na($node/@type,(
               for $n in $node/*[local-name(.) eq $model/@name]
               return 
                   model:to-json($model,$n)
            ))
         ))
     else ()