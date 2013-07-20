xquery version "1.0-ml";
(:~
 : Controls request/response pipeline interception.  In cases where the application requires the ability to intercept
 : the request/response at various points in the execution context of the dispatcher. 
 :
~:)
module namespace interceptor = "http://www.xquerrail-framework.com/interceptor";

import module namespace config = "http://www.xquerrail-framework.com/config"
   at "config.xqy";
   
import module namespace request = "http://www.xquerrail-framework.com/request"
   at "request.xqy";

import module namespace response = "http://www.xquerrail-framework.com/response"
   at "response.xqy";
   
declare option xdmp:mapping "false";

(:~
 : Returns the interceptor configuration for the application. This is a wrapper call for config:interceptor-config()
~:)
declare function interceptor:config() as element()
{
   config:interceptor-config()
};
(:~
 : Returns the context node associated with the current application:controller:action
~:)declare function interceptor:get-context()
{
   fn:string-join((
       xdmp:get-request-field("_application",config:default-application()),
       xdmp:get-request-field("_controller",config:default-controller()),
       xdmp:get-request-field("_action",config:default-action()))
    ,":")
};
(:~
 : Returns a list of matching scopes from an interceptor configuration
 : @param $configuration - Configuration XML definition
~:)
declare function interceptor:get-matching-scopes($configuration) {
   let $context := interceptor:get-context()
   let $context-tokens := fn:tokenize($context,":")
   let $scopes := $configuration/config:scope
   return (
      $scopes[@context eq $context], 
      for $scope in $scopes
      let $scope-tokens := fn:tokenize($scope/@context,":")
      let $matches := 
         for $scope-token at $pos in $scope-tokens
         return 
             if($scope-token eq "*") 
             then fn:true()
             else $scope-tokens[$pos] eq $context-tokens[$pos]             
      where every $m in $matches satisfies $m eq fn:true()
      return
          $scope
  )          
};
(:~
 : Executes all before request interceptor(s) using the given configuration for that interceptor
 : The before-request interceptor executes before the response has been created or initialized
~:)
declare function interceptor:before-request (
) {
   for $int in config:get-interceptors("before-request")
   let $location-uri := fn:concat("/_framework/interceptors/interceptor.",$int/@name,".xqy")
   let $function     := xdmp:function(xs:QName("interceptor:before-request"),$location-uri)
   let $config := 
      if($int/@resource) 
      then xdmp:invoke($int/@resource)
      else if($int/@dbresource) then
          fn:doc($int/@dbresource)
      else <config/>
   let $invoke := xdmp:apply($function,$config)
   return (
     if($invoke instance of map:map) 
     then request:initialize($invoke)
     else (),
     xdmp:log(("interceptor:ml-security::before-request",$config,"debug"))
  )
};
(:~
 : Executes all after-request interceptors.  The after-request interceptor is called after the response has been initializes 
 : and the controller action has been called.
 : @param $request - A request map that correspondes to the current request map.
~:)
declare function interceptor:after-request(
$request as map:map
){(
   for $int in config:get-interceptors("after-request")
   let $_ := xdmp:log(("interceptor:ml-security::after-request",()),"debug")
   let $location-uri := fn:concat("/_framework/interceptors/interceptor.",$int/@name,".xqy")
   let $function     := xdmp:function(xs:QName("interceptor:after-request"),$location-uri)
   let $config := 
      if($int/@resource) 
      then xdmp:invoke($int/@resource)
      else if($int/@dbresource) then
          fn:doc($int/@dbresource)
      else <config/>
   let $invoke := xdmp:apply($function,$request,$config)
   return 
     if($invoke instance of map:map) 
     then request:initialize($invoke)
     else ()  
)};
(:~
 : Executes all interceptors after the controller action has been called and before the response is processed by the designated engine.
~:)
declare function interceptor:before-response(
)
{(
   for $int in config:get-interceptors("before-response")
   let $_ := xdmp:log(("interceptor:ml-security::before-response",()),"debug")
   let $location-uri := fn:concat("/_framework/interceptors/interceptor.",$int/@name,".xqy")
   let $function     := xdmp:function(xs:QName("interceptor:before-response"),$location-uri)
   let $config := 
      if($int/@resource) 
      then xdmp:invoke($int/@resource)
      else if($int/@dbresource) then
          fn:doc($int/@dbresource)
      else <config/>
   let $invoke := xdmp:apply($function,$config)
   return 
     if($invoke instance of map:map) 
     then request:initialize($invoke)
     else ()  
)};
(:~
 : Executes all interceptors after the response has been rendered by the engine
 : and is flushed out to the calling context.
~:)
declare function interceptor:after-response(
){(
   for $int in config:get-interceptors("after-response")
   let $_ := xdmp:log(("interceptor:ml-security::after-response",()),"debug")
   let $location-uri := fn:concat("/_framework/interceptors/interceptor.",$int/@name,".xqy")
   let $function     := xdmp:function(xs:QName("interceptor:after-response"),$location-uri)
   let $config := 
      if($int/@resource) 
      then xdmp:invoke($int/@resource)
      else if($int/@dbresource) then
          fn:doc($int/@dbresource)
      else <config/>
   let $invoke := xdmp:apply($function,$config)
   return 
     if($invoke instance of map:map) 
     then request:initialize($invoke)
     else ()  
)};
