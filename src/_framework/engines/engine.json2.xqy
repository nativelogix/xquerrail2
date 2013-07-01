xquery version "1.0-ml";

module namespace base = "http://www.xquerrail-framework.com/engine";
    
import module namespace engine  = "http://www.xquerrail-framework.com/engine"
  at "/_framework/engines/engine.base.xqy";
  
import module namespace config = "http://www.xquerrail-framework.com/config"
  at "/_framework/config.xqy";

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

import module namespace js = "http://www.xquerrail-framework.com/helper/javascript-builder"
   at "/_framework/helpers/javascript.xqy";

import module namespace jsb = "http://www.xquerrail-framework.com/helper/json"
    at "/_framework/helpers/json-builder.xqy";

declare namespace tag = "http://www.xquerrail-framework.com/tag";  

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "method=xml";

(:~
 : You initialize your variables
~:)
declare variable $request := map:map() ;
declare variable $response := map:map();
declare variable $context := map:map();

(:~
   Initialize  Any custom tags your engine handles so the system can call 
   your custom transform functions
~:)
declare variable $custom-engine-tags as xs:QName*:= 
(
  fn:QName("engine","x-json")
);
(:Set your engines custom transformer:)
declare variable $custom-transform-function := 
   xdmp:function(
     xs:QName("engine:custom-transform"),
     "/_framework/engines/engine.json.xqy"
);
(:~
 : The Main Controller will call your initialize method
 : and register your engine with the engine.base.xqy
~:)
declare function engine:initialize($_response,$_request){ 
(
  let $init := 
  (
       response:initialize($_response),
       request:initialize($_request),
       xdmp:set($response,$_response),
       engine:set-engine-transformer($custom-transform-function),
       engine:register-tags($custom-engine-tags)
  )
  return
   engine:render()
)
};

declare function engine:get-view-uri($response) {
   if(response:base()) 
   then fn:concat("/_framework/base/views/base.",response:view(),".json.xqy")
   else fn:concat("/",request:application(),"/views/", request:controller(),"/",request:controller(), ".", response:view(),".json.xqy")
};

(:~
 : No need to use the views 
~:)
declare function engine:internal-render-view($response)
{
   if(engine:view-exists(engine:get-view-uri($response)))
   then 
   xdmp:invoke(
       engine:get-view-uri($response),
       (xs:QName("response"),$response)
   ) else ()
};

declare function engine:recursive-transform($node,$model)
{
    typeswitch($node)
    case document-node() return 
        <json type="object">{
          for $n in $node/(attribute()|element())
          return
             engine:recursive-transform($n,$model)      
        }</json>
    case element() return
       let $name  := fn:local-name($node)
       let $field := $model//(domain:model|domain:element|domain:attribute)[fn:local-name(.) eq $name]
       let $type  := if($field) then $field/@type else "string"
       return 
         if($type = ("string")) 
         then element { attribute type{"string"}, fn:local-name($node) } {fn:data($node)}
         else $node
    default return ()      
};

declare function engine:render-json($node)
{  
   let $is-listable := $node instance of element(list) 
   let $is-lookup   := $node instance of element(lookups)
   let $model := 
      if($is-listable or $is-lookup)
      then domain:get-domain-model($node/@type)
      else domain:get-domain-model(fn:local-name($node)) 
   let $_ := xdmp:log(($model,"Body:::",xdmp:describe($node)),"debug")
   return
     if($is-listable and $model) then  
         js:json(
            js:o((       
            js:kv("currentpage",$node/currentpage cast as xs:integer),
            js:kv("pagesize",$node/pagesize cast as xs:integer),
            js:kv("totalpages",$node/totalpages cast as xs:integer),
            js:kv("totalrecords",$node/totalrecords cast as xs:integer),
            js:e($node/@type,(
               for $n in $node/*[local-name(.) eq $model/@name]
               return 
                   model:to-json($model,$n)
            ))
         )))
     else if($is-lookup) then
          js:json(js:o ((
             js:e("lookups",
             for $n in $node/*:lookup
             return js:o((
                js:e("key",fn:string($n/*:key)),
                js:e("label",fn:string($n/*:label))
             )))
          ))     
        )     
     else if($model) then (
             model:to-json($model,$node)
          )
     else (:fn:error(xs:QName("JSON-PROCESSING-ERROR"),"Cannot generate JSON response without model"):)
        jsb:to-json($node)
};
(:~
  Handle your custom tags in this method or the method you have assigned  
  initialized with the base.engine
  It is important that you only handle your custom tags and
  any content that is required to be consumed by your tags
~:)
declare function engine:custom-transform($node as item())
{  
   $node
};
(:~
 : The Kernel controller will call your render method.
 : From this point it is up to your engine  
 : to initialize any specific response settings and
 : and start the rendering process 
~:)
declare function engine:render()
{
   if(response:redirect()) 
   then xdmp:redirect-response(response:redirect())
   else 
   (
     (:Set the response content type:)
     if(response:content-type())
     then xdmp:set-response-content-type(response:content-type())
     else xdmp:set-response-content-type("application/json"),  
     for $key in map:keys(response:response-headers())
     return xdmp:add-response-header($key,response:response-header($key)),
     let $view := if(response:view()) then engine:internal-render-view($response) else ()
     return 
        if($view)
        then if($view instance of element(json)) then json:xmlToJSON($view) else $view
        else if(response:body()) 
             then engine:render-json(response:body())
        else ()
   )
};

