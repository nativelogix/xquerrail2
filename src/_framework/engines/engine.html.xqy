xquery version "1.0-ml";

module namespace base = "http://xquerrail.com/engine";
    
import module namespace engine  = "http://xquerrail.com/engine"     at "/_framework/engines/engine.base.xqy";
import module namespace config = "http://xquerrail.com/config"      at "/_framework/config.xqy";
import module namespace routing = "http://xquerrail.com/routing"    at "/_framework/routing.xqy";
import module namespace domain = "http://xquerrail.com/domain"      at "/_framework/domain.xqy";
import module namespace request = "http://xquerrail.com/request"    at "/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response"  at "/_framework/response.xqy";
   
declare namespace tag = "http://xquerrail.com/tag";  

declare default element namespace "http://www.w3.org/1999/xhtml";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "indent=yes";
declare option xdmp:output "method=xml";
declare option xdmp:ouput "omit-xml-declaration=yes";

(:Internal Holders for request, response and context:)
declare variable $request := map:map() ;
declare variable $response := map:map();
declare variable $context := map:map();

(:~
 : Custom Tags the HTML Engine renders and handles during transform
 :)
declare variable $engine-tags := 
(  
     xs:QName("engine:title"),
     xs:QName("engine:include-metas"),
     xs:QName("engine:include-http-metas"),
     xs:QName("engine:controller-script"),
     xs:QName("engine:controller-stylesheet"),
     xs:QName("engine:controller-list"),
     xs:QName("engine:flash-message"),
     xs:QName("engine:resource"),
     xs:QName("engine:javascript-include"),
     xs:QName("engine:stylesheet-include"),
     xs:QName("engine:resource-include"),
     xs:QName("engine:image-tag"),
     xs:QName("engine:controller-link")
);

(:~
 : Initialize the engine passing the request and response for the given object.
 :)
declare function engine:initialize($resp,$req){ 
    (
      let $init := 
      (
           response:initialize($resp),
           xdmp:set($response,$resp),
           engine:set-engine-transformer(xdmp:function(xs:QName("engine:custom-transform"),"/_framework/engines/engine.html.xqy")),
           engine:register-tags($engine-tags)
      )
      return
       engine:render()
    )
};
(:~
 : Some Common settings for html 
 :)
declare variable $html-strict :=        '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">';
declare variable $html-transitional :=  '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
declare variable $html-frameset :=      '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">';
declare variable $xhtml-strict :=       '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
declare variable $xhtml-transitional := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
declare variable $xhtml-frameset :=     '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">';
declare variable $xhtml-1.1 :=          '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">';

(:~
 : Returns a <meta/> element for use in http header
 :)
declare function engine:transform-include_metas($node as node())
{
  response:metas()
};

(:~
 :  Renders out HTTP meta elements to header
 :)
declare function engine:transform-http_metas($node as node())
{
  response:httpmetas()
};

(:~
 : Custom Tag for rendering Label or Title of Controller.  This is set using the
 : response:set-title("MY Title") function during controller invocation
 :)
declare function engine:transform-title($node as node())
{
   response:title()
};



(:~
 : Generates a script element for the given controller.  If a controller 
 : script is defined in the template the system will check to see if the
 : file exists on the system before rendering any output
 :)
declare function engine:transform-controller-script($node)
{
  let $script-directory := config:application-script-directory(response:application())
  let $script-uri := fn:concat($script-directory,"/",response:controller(),".js")
  
  return 
  if(response:controller() ne "" and engine:module-file-exists($script-uri)) 
  then element script {
          attribute type{"text/javascript"},
          attribute src {$script-uri},
          text{"//"}
          }
  else xdmp:log(("No controller-script::" || $script-uri))
};
(:~
 : Generates a script element for the given controller.  If a controller 
 : script is defined in the template the system will check to see if the
 : file exists on the system before rendering any output
 :)
declare function engine:transform-controller-stylesheet($node)
{
  let $stylesheet-directory := config:application-stylesheet-directory(response:application())
  let $stylesheet-uri := fn:concat($stylesheet-directory,if(fn:ends-with($stylesheet-directory,"/")) then () else "/",response:controller(),".css")
   return 
  if(response:controller() ne "" and engine:module-file-exists($stylesheet-uri))  
  then element link {
          attribute type{"text/css"},
          attribute href {$stylesheet-uri},
          attribute rel {"stylesheet"},
          text{""}
          }
  else ()
};

(:~
 : Generates a script element for the given controller.  If a controller 
 : script is defined in the template the system will check to see if the
 : file exists on the system before rendering any output
 :)
declare function engine:transform-javascript-include($node)
{
  let $script-directory := config:resource-directory() 
  let $resource := fn:data($node) ! fn:replace(.,'&quot;','')  ! fn:normalize-space(.)
  let $script-uri := 
    fn:concat(
        $script-directory,
        if(fn:ends-with($script-directory,"/")) then () else "/",
        config:property("js-path"), "/",
        $resource,
        if(fn:ends-with($script-directory,"/")) then () else "/",
        ".js")
  return 
  if(engine:module-file-exists($script-uri)) 
  then element script {
          attribute type{"text/javascript"},
          attribute src {$script-uri},
          text{"//"}
          }
  else fn:error(xs:QName("INCLUDE-ERROR"),"Invalid path:" || $script-uri)
};

(:~
 : Generates a script element for the given controller.  If a controller 
 : script is defined in the template the system will check to see if the
 : file exists on the system before rendering any output
 :)
declare function engine:transform-stylesheet-include($node)
{
  let $resource := fn:data($node) ! fn:replace(.,"&quot;","") ! fn:normalize-space(.)
  let $stylesheet-directory :=  config:resource-directory() 
  let $stylesheet-uri := 
  fn:concat(
        $stylesheet-directory,
        if(fn:ends-with($stylesheet-directory,"/")) then () else "/",
        config:property("css-path"),
        $resource,".css")
   return 
  if(engine:module-file-exists($stylesheet-uri))  
  then element link {
          attribute type{"text/css"},
          attribute href {$stylesheet-uri},
          attribute rel {"stylesheet"},
          text{""}
          }
  else fn:error(xs:QName("INCLUDE-ERROR"),"Invalid path:" || $stylesheet-uri)
};
(:~
 :  Creates 
 :)
declare function engine:transform-image-tag($node)
{
  let $resource := fn:data($node) ! fn:replace(.,"&quot;","") ! fn:normalize-space(.)
  let $image-directory :=  config:resource-directory() 
  let $image-uri := 
  fn:concat(
        $image-directory,
        if(fn:ends-with($image-directory,"/")) 
        then () 
        else "/",
        config:resource-directory(),
        $resource)
   return 
  if(engine:module-file-exists($image-uri))  
  then element img {
          attribute src {$image-uri},
          text{""}
          }
  else ()
};
(:~
 : Generates a script element for the given controller.  If a controller 
 : script is defined in the template the system will check to see if the
 : file exists on the system before rendering any output
 :)
declare function engine:transform-resource-include($node)
{
  let $resource := fn:data($node) ! fn:replace(.,"&quot;","") ! fn:normalize-space(.)
  let $resource-directory :=  config:resource-directory() 
  let $extension := fn:tokenize($resource,"\.")[fn:last()]
  let $resource-uri := 
  fn:concat(
        $resource-directory,
        if(fn:ends-with($resource-directory,"/")) then () else "/",
        $resource)
   return 
       switch($extension)
         case "css" return
            element link {
                  attribute type{"text/css"},
                  attribute href {$resource-uri},
                  attribute rel {"stylesheet"},
                  text{""}
                  }
         case "js" return
            element script {
              attribute type {"text/javascript"},
              attribute src {$resource-uri}
               
            }
         default return fn:error(xs:QName("UNKNOWN-RESOURCE"),"Unknown Resource Error")  
};
(:~
 :  Returns a `<ul><li>` list of controllers and their corresponding links
 :  This can be used during app generation to quickly test
 :  New controllers. 
 :)
declare function engine:transform-controller-list($node)
{
   let $attributes := xdmp:value(fn:concat("<attributes ", fn:data($node),"/>"))
   let $base-uri := ($attributes/@base,"/")[1]
   return
   <ul>{
   if($attributes/@uiclass) then attribute class {$attributes/@uiclass} else (),
   if($attributes/@id) then $attributes/@id else (),
   if($attributes/@class) 
   then
        for $controller in domain:get-controllers(request:application())[@class = $attributes/@class]
        return
          <li>
            {if($attributes/@itemclass) then attribute class {$attributes/@itemclass} else ()}
            <a href="/{$base-uri}/{$controller/@name}/index.html">{(fn:data($controller/@label),fn:data($controller/@name))[1]}</a>
          </li>   
   else 
        for $controller in domain:get-controllers(request:application())
        return
          <li>
            {if($attributes/@itemclass) then attribute class {$attributes/@itemclass} else ()}
            <a href="/{$base-uri}/{$controller/@name}/index.html">{(fn:data($controller/@label),fn:data($controller/@name))[1]}</a>
          </li>
   }</ul>
};

(:~
 :  Returns a list of controllers as a unordered list.
 :  This can be used during app generation to quickly test
 :  New controllers. 
 :)
declare function engine:transform-flash-message($node)
{
   response:flash(fn:data($node))
};

declare function engine:transform-controller-link($node) {
 let $attributes := xdmp:value(fn:concat("<attributes ", fn:data($node),"/>"))
 let $controller := $attributes/@controller
 let $action := ($attributes/@action,"index")[1]
 let $format :=  "." || ($attributes/@format,"html")[1]
 let $text-body := fn:data($attributes/@text)
 return
   <a href="{$controller}/{$action}{$format}">
   {$attributes/(@class|@alt)}
   {$text-body}
   </a>
};
(:~
 : Custom Transformer handles HTML specific templates and
 : Tags.
 :)
declare function engine:custom-transform($node as node())
{  
   if(engine:visited($node))
   then  ()    
   else(
       typeswitch($node)
         case processing-instruction("title")              return engine:transform-title($node)
         case processing-instruction("include-http-metas") return engine:transform-http_metas($node)
         case processing-instruction("include-metas")      return engine:transform-include_metas($node)
         case processing-instruction("javascript-include") return engine:transform-javascript-include($node)
         case processing-instruction("stylesheet-include") return engine:transform-stylesheet-include($node)
         case processing-instruction("resource-include")   return engine:transform-resource-include($node)
         case processing-instruction("image-tag")          return engine:transform-image-tag($node)
         case processing-instruction("controller-script")  return engine:transform-controller-script($node)
         case processing-instruction("controller-stylesheet") return engine:transform-controller-stylesheet($node)
         case processing-instruction("controller-list")    return engine:transform-controller-list($node)
         case processing-instruction("controller-link")    return engine:transform-controller-link($node)
         case processing-instruction("flash-message")      return engine:transform-flash-message($node)
         case processing-instruction()                     return engine:transform($node)   
         default return engine:transform($node)
     )    
};
(:~
 : Handles redirection.
 : The redirector will try to ensure a valid route is defined to handle the request
 : If the redirect does not map to an existing route then 
 : will throw invalid redirect error.
 :)
declare function engine:redirect($path)
{
     let $controller := response:controller()
     let $action     := $path
     let $format     := response:format()
     let $route-uri  := 
        if(fn:contains($path,"/")) 
        then $path 
        else fn:concat('/',$controller,'/',($action,config:default-action())[1],'.',($format,config:default-format())[1])
     let $route      := routing:get-route($route-uri)
     return
        if($route) 
        then xdmp:redirect-response($route-uri)
        else fn:error(xs:QName("INVALID-REDIRECT"),"No valid Routes")
};
(:~
 : Renders the HTML response and adds response information such as headers and response codes.
 :)
declare function engine:render()
{
   if(response:redirect()) 
   then engine:redirect(response:redirect())
   else 
   (
     (:Set the response content type:)
     if(response:content-type())
     then xdmp:set-response-content-type(response:content-type())
     else xdmp:set-response-content-type("text/html"),
     for $key in map:keys(response:response-headers())
     return 
        xdmp:add-response-header($key,response:response-header($key)),
        if(response:partial()) 
        then ()
        else  '<!doctype html>',
     if(response:partial()) 
     then engine:render-view()
     else if(response:template()) 
     then engine:render-template($response)
     else if(response:view())
     then engine:render-view()
     else if(response:body()) 
          then response:body()
     else ()   
   )
};