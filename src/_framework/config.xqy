(:~
 : Provides access to config and supports retrieving resources from configuration entries
 : @version 1.1
 :)
xquery version "1.0-ml";

module namespace config = "http://www.xquerrail-framework.com/config";

import module namespace response = "http://www.xquerrail-framework.com/response"
   at "/_framework/response.xqy";
   
import module namespace request  = "http://www.xquerrail-framework.com/request"
   at "/_framework/request.xqy";

declare namespace domain = "http://www.xquerrail-framework.com/domain";

declare namespace routing = "http://www.xquerrail-framework.com/routing";   

declare option xdmp:mapping "false";

(:
 :Make sure this points to a valid location in your modules path
 :)   
declare variable $CONFIG  := 
    if(xdmp:modules-database() = 0 ) 
    then xdmp:invoke("/_config/config.xml")
    else 
      xdmp:eval("fn:doc('/_config/config.xml')/element()",
      (),
      <options xmlns="xdmp:eval">
         <database>{xdmp:modules-database()}</database>
      </options>
      )
 ;
(:Default Path Values:)

(:~
 : Defines the default base path framework
~:)
declare variable $FRAMEWORK-PATH           := "/_framework";
(:~
 : Defines the default base path for engines
~:)
declare variable $DEFAULT-ENGINE-PATH      := "/_framework/engines";
(:~
 : Defines the default base path for all interceptors
~:)
declare variable $DEFAULT-INTERCEPTOR-PATH := "/_framework/interceptors";
(:~
 : Defines the default base path for all dispatches
~:)
declare variable $DEFAULT-DISPATCHER-PATH  := "/_framework/dispatchers";
(:~
 : Defines the base implementation path for controllers,models and views
~:)
declare variable $DEFAULT-BASE-PATH        := "/_framework/base";
(:~
 : Defines the default location of views used in dynamic view functions
~:)
declare variable $DEFAULT-VIEWS-PATH       := fn:concat($DEFAULT-BASE-PATH,"/views");
(:~
 : Defines the default location of templates in dynamic ui functions
~:)
declare variable $DEFAULT-TEMPLATE-PATH    := fn:concat($DEFAULT-BASE-PATH,"/templates");

(:~
 : Defines the Default Controller Resources
~:)
declare variable $DEFAULT-CONTROLLER-RESOURCE  := fn:concat($DEFAULT-BASE-PATH,"/base-controller.xqy");
(:~
 : Defines the Default Model Resource 
~:)
declare variable $DEFAULT-MODEL-RESOURCE       := fn:concat($DEFAULT-BASE-PATH,"/base-model.xqy");


(:~
 : Defines the default anonymous-user configuration
~:)
declare variable $DEFAULT-ANONYMOUS-USER   := "anonymous-user";
(:~
 : Defines the default routing module configuration
~:)
declare variable $DEFAULT-ROUTING-MODULE   := "/_framework/routing.xqy";

(:Error Codes:)
declare variable $ERROR-RESOURCE-CONFIGURATION := xs:QName("ERROR-RESOURCE-CONFIGURATION");
declare variable $ERROR-ROUTING-CONFIGURATION  := xs:QName("ERROR-ROUTING-CONFIGURATION");
declare variable $ERROR-DOMAIN-CONFIGURATION   := xs:QName("ERROR-DOMAIN-CONFIGURATION");

declare variable $DOMAIN-CACHE-KEY := "application-domain::" ;
declare variable $DOMAIN-CACHE-TS := "application-domains:timestamp::";

(:~
  Initializes the application domains and caches them in the applicatino server. 
  When using a cluster please ensure you change configuration to cache from database
 :)
declare function config:refresh-app-cache() {
   for $sf in xdmp:get-server-field-names()
   return 
   if(fn:starts-with($sf,$DOMAIN-CACHE-KEY))  then
      let $app-path := config:application-directory(fn:substring-after($sf, $DOMAIN-CACHE-KEY))
      let $domain-key := fn:concat($app-path,"/domains/application-domain.xml")
      let $config := config:get-resource(fn:concat($app-path,"/domains/application-domain.xml"))
      let $config := config:_load-domain($config)
      return (
        xdmp:set-server-field($sf,$config)
      )
   else ()
};
(:~
 : Returns a list of applications from the config.xml
~:)
declare function config:get-applications() {
   $CONFIG/domain:application
};


(:~Function Returns a resource based on 
 : how the application server is configured.
 : If the modules are in the filesystem.  It invokes the modules
 : If the modules are in a modules database then it evals the call to the modules database using the uri
~:)
declare function config:get-resource($uri as xs:string) {
    if(xdmp:modules-database() = 0 ) 
    then xdmp:invoke($uri)
    else 
      xdmp:eval("fn:doc('" || $uri || "')/element()",
      (),
      <options xmlns="xdmp:eval">
         <database>{xdmp:modules-database()}</database>
      </options>
      )
};

(:~
 : Retrieves the config value. 
:)
declare function config:get-dbresource($uri as xs:string) {
   fn:doc($uri)
};

(:~
 : Returns a configuration value of the given resource
 :)
declare function config:get-config-value($node as element()?) {
   if($node/@dbresource) 
   then config:get-dbresource(fn:data($node/@dbresource))
   else if($node/@resource) 
        then config:get-resource(fn:data($node))
   else if($node/@value) 
        then fn:data($node/@value)
   else if(fn:not(fn:exists($node)))
        then ()
   else fn:error(xs:QName("INVALID_CONFIGURATION_VALUE"),
        "A configuration value must be an attribute whose name is @resource,@dbresource,@value",$node)
};
(:~
 : Returns the default application defined in the config or application config
 : The default application is "application"
 :)
 declare function config:default-application()
 {
    ($CONFIG/config:default-application/@value/fn:string(),"application")[1]
 }; 
(:~
 : Returns the default controller for entire application usually default
 :)
declare function config:default-controller()
{
  fn:string($CONFIG/config:default-controller/@value)
};

declare function config:default-template($application-name) {
  (
   config:get-application($application-name)/config:default-template/@value/fn:string(),
   $CONFIG/config:default-template/@value/fn:string(),
   "main"
   )[1]
};
(:~
 : Returns the resource directory for framework defined in /_config/config.xml
~:)
declare function config:resource-directory() as xs:string
{
   if(fn:not($CONFIG/config:resource-directory))
   then "/resources/"
   else fn:data($CONFIG/config:resource-directory/@resource)
}; 

(:~
 : Returns the default action 
:)
declare function config:default-action()
{
  fn:string($CONFIG/config:default-action/@value)
};

(:~
 : Returns the default format
 :)
declare function config:default-format()
{
  fn:string($CONFIG/config:default-format/@value)
};

(:~
 : returns the default dispatcher for entire framework.
 :)
declare function config:get-dispatcher()
{
  fn:string($CONFIG/config:dispatcher/@resource)
};

(:~
 : returns the application configuration for a given application by name
 : @param application-name Application name
 :)
declare function config:get-application($application-name as xs:string)
{
   $CONFIG/config:application[@name eq $application-name]
};

(:~
 : Get the current application directory
 :)
declare function config:application-directory($application-name)
{
   fn:concat(config:get-application($application-name)/@uri)
};
(:~
 : Get the current application script directory
 :)
declare function config:application-script-directory($application-name)
{
   (fn:data(config:get-application($application-name)/config:script-directory/@value),
    config:resource-directory())[1]
};
(:~
 : Get the current application directory
 :)
declare function config:application-stylesheet-directory($name)
{
   (
    fn:data(config:get-application($name)/config:stylesheet-directory/@value),
    config:resource-directory()
   )[1]
};

(:~
 : Gets the current view directory defined in the configuration
~:)
declare function config:base-view-directory() {
   let $dir :=  fn:data($CONFIG/config:base-view-location/@value)
   return 
    if ($dir) then $dir else "/_framework/base/views"
};

(:~
 : Gets the default anonymous user
 :)
declare function config:anonymous-user()
{
   config:anonymous-user(config:default-application())
};

(:~
 : Gets the default anonymous user
 :)
declare function config:anonymous-user($application-name)
{(
   fn:data($CONFIG/config:anonymous-user/@value),
   "anonymous"
)[1]};


(:~
 :  Get the domain for a given application
 :  @param $application-name - Name of the application
 :)
declare function config:get-domain($application-name)
{
  let $cache-key := fn:concat($DOMAIN-CACHE-KEY,$application-name)
  return 
  if(xdmp:get-server-field($cache-key)) 
  then xdmp:get-server-field($cache-key)
  else 
    let $app-path := config:application-directory($application-name)
    let $domain-key := fn:concat($app-path,"/domains/application-domain.xml")
    let $domain := config:get-resource(fn:concat($app-path,"/domains/application-domain.xml"))
    let $domain := config:_load-domain($domain)
    return (
      xdmp:set-server-field($cache-key,$domain),
      $domain
    )
};
(:~
 : Function loads the domain internally and resolves import references
~:)
declare %private function config:_load-domain(
$domain as element(domain:domain)
) {
    let $app-path := config:application-directory($domain/*:name)
    let $imports := 
        for $import in $domain/domain:import
        return
            config:get-resource(fn:concat($app-path,"/domains/",$import/@resource))    
    
    return 
        element domain {
         namespace domain {"http://www.xquerrail-framework.com/domain"},
         attribute xmlns {"http://www.xquerrail-framework.com/domain"},
         $domain/@*,
         $domain/(domain:name|domain:content-namespace|domain:application-namespace|domain:description|domain:author|domain:version|domain:declare-namespace|domain:default-collection),
         ($domain/domain:model,$imports/domain:model),
         ($domain/domain:optionlist,$imports/domain:optionlist),
         ($domain/domain:controller,$imports/domain:controller),
         ($domain/domain:view,$imports/domain:view)
       } 
};

(:~
 : Returns the routes configuration file 
 :)
declare function config:get-routes()
{
  config:get-resource($CONFIG/config:routes-config/@resource) 
};

(:~
 : Returns the routing module 
 :)
declare function config:get-route-module() {
   $CONFIG/config:routes-module/@resource
};

(:~
 : Returns the engine for processing requests satisfying the request
 :)
declare function config:get-engine($response as map:map)
{
   let $_ := response:set-response($response)
   return
     if(response:format() eq "html") 
     then "engine.html"
     else if(response:format() eq "xml")
     then "engine.xml"
     else if(response:format() eq "json")
     then "engine.json"
     else fn:string($CONFIG/config:default-engine/@value)
};

(:~
 : Returns the engine for processing requests satisfying the request
 :)
declare function config:get-model-xqy-path($model-name as xs:string) {

    let $modelSuffix := fn:data($CONFIG/config:model-suffix/@value)
    let $path := fn:concat("/model/", $model-name, $modelSuffix, ".xqy")
    
    return
     if(xdmp:uri-is-file($path))
     then $path
     else fn:concat("/_framework/base/base", $modelSuffix, ".xqy")
};

declare function config:error-handler()
{ 
  (
    $CONFIG/config:error-handler/@resource,
    $CONFIG/config:error-handler/@dbresource,
    "/_framework/error.xqy"
  )[1]
};
(:Returns the list of all interceptors defined in the system:)
declare function config:get-interceptors()
{
  config:get-interceptors(())
};

(:~
 : Returns all interceptors that match a given value
~:)
declare function config:get-interceptors(
  $value as xs:string?
){
  if($value) 
  then $CONFIG/config:interceptors
     /config:interceptor[
      if($value eq "before-request")       then ./@before-request eq "true" 
      else if($value eq "after-request")   then ./@after-request eq "true"
      else if($value eq "before-response") then ./@before-response eq "true"
      else if($value eq "after-response")  then ./@after-response eq "true"
      else if($value eq "all") then fn:true()
      else fn:false()
     ]
  else ()
};
(:~
 : Returns the default interceptor configuration.  If none is configured will map to the default
~:)
declare function config:interceptor-config() as xs:string?
{
   (
     $CONFIG/config:interceptor-config/@value/fn:data(.),
     "/_config/interceptor.xml"
   )[1]
   
};
