xquery version "1.0-ml";
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and 
 : definitions for dynamic features built into XQuerrail.  
 : @version 2.0
 :) 
module namespace domain = "http://xquerrail.com/domain";

import module namespace config = "http://xquerrail.com/config"
at "/_framework/config.xqy";

declare option xdmp:mapping "false";

(:~
 : A list of QName's that define in a model
 :)   
declare variable $DOMAIN-FIELDS := 
   for  $fld in ("domain:model","domain:container","domain:element","domain:attribute") 
   return  xs:QName($fld);
(:~
 : A list of QName's that define model node fields excluding the model
 :)   
declare variable $DOMAIN-NODE-FIELDS := 
   for  $fld in ("domain:container","domain:element","domain:attribute") 
   return  xs:QName($fld);

declare variable $COLLATION := "http://marklogic.com/collation/codepoint";

(:~
 : Holds a cache of all the domain models
 :)
declare variable $DOMAIN-MODEL-CACHE := map:map();

(:Holds a cache of all the identity fields:)
declare variable $DOMAIN-IDENTITY-CACHE := map:map();

(:~
 : Gets the domain model from the given cache
 :)
declare %private function domain:get-model-cache($key) {
   map:get($DOMAIN-MODEL-CACHE,$key)
};

(:~
 : Sets the cache for a domain model
 :)
declare %private function domain:set-model-cache($key,$model as element(domain:model)) {
   map:put($DOMAIN-MODEL-CACHE,$key,$model)
};

(:~
 : Gets the value of an identity cache from the map
 : @private
 :)
declare %private function domain:get-identity-cache($key) {
  let $value := map:get($DOMAIN-IDENTITY-CACHE,$key)
  return
    if($value) then $value else ()
};
(:~
 : Sets the cache value of a models identity field for fast resolution
 : @param $key - key string to identify the cache identity
 : @param $value - $value of the cache item
 :)
declare function domain:set-identity-cache($key as xs:string,$value as item()*) {
  map:put($DOMAIN-IDENTITY-CACHE,$key,$value)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field-name($model as element(domain:model))  {
  $model//(domain:element|domain:attribute)[@identity eq "true" or @type eq "identity"]/fn:string(@name)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field($model as element(domain:model)) {
  let $key := fn:concat($model/@name , ":identity")
  let $cache := domain:get-identity-cache($key)
  return
    if($cache) then $cache
    else 
    let $field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][./@identity eq "true" or ./@type eq "identity"]
    return (
     domain:set-identity-cache($key,$field),
     $field
    )
};
(:~
 : Returns the identity query for a domain-model
 : @param $domain-model - The domain model for the identity-query
 : @param $value - The value of the domain instance for retrieval
 :)
declare function domain:get-model-identity-query(
  $domain-model as element(domain:model),
  $value as xs:anyAtomicType?
) {
  let $id-field := domain:get-model-identity-field($domain-model)
  let $id-ns    := domain:get-field-namespace($id-field)
  return  
    typeswitch($id-field)
      case element(domain:element) return
        cts:element-range-query(
          fn:QName($id-ns,$id-field/@name),
          "=",
          $value)
        
      case element(domain:attribute) return 
        let $parent-elem := $id-field/parent::*[domain:element|domain:model]
        let $parent-ns   := domain:get-field-namespace($parent-elem)
        return  
          cts:element-attribute-range-query(
              fn:QName($parent-ns,$parent-elem/@name),
              fn:QName("",$id-field/@name),
              "=",
              $value
          )
      default return 
        fn:error(
            xs:QName("IDENTITY-QUERY"),
            "Identity Query could not be resolved.",
            fn:data($domain-model/@name)
        )    
      
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-key-field($model as element(domain:model)) {
    let $key := ($model/@name || ":key")
    let $cache := domain:get-identity-cache($key)
    return
        if($cache) then $cache
        else 
            let $field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][@name eq $model/@key]
            return (
               domain:set-identity-cache($key,$field),
               $field
            )
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keyLabel-field($model as element(domain:model)) {
    let $key := ($model/@name || ":keyLabel")
    let $cache := domain:get-identity-cache($key)
    return
        if($cache) then $cache
        else 
            let $field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][@name eq $model/@keyLabel]
            return (
               domain:set-identity-cache($key,$field),
               $field
            )
};
(:~
 : Returns the field that matches the given field name or key
 : @param $model - The model to extract the given field
 : @param $name  - name or key of the field
 :)
declare function domain:get-model-field($model as element(domain:model),$key as xs:string) {
  $model//(domain:element|domain:attribute)[$key = @name]
};

(:~
 : Returns model fields with unique constraints
 : @param $model - The model that returns all the unique constraint fields
 :)
declare function domain:get-model-unique-constraint-fields($model as element(domain:model)) {
   $model//(domain:element|domain:attribute)[domain:constraint/@unique = "true"]
};

(:~
 : Resolves a domain type to xsi:type
 : @param $model - The model to extract the given identity field
 :)
declare function domain:resolve-datatype(
    $field as element()
) {
   let $data-type := element{$field/@type}{$field}
   return 
     typeswitch($data-type)
     case element(uuid) return "xs:string"
     case element(identity) return "xs:ID"
     case element(create-timestamp) return "xs:dateTime"
     case element(create-user) return "xs:string"
     case element(update-timestamp) return "xs:dateTime"
     case element(update-user) return "xs:string"
     case element(modify-user) return "xs:string"
     case element(binary) return "binary()"
     case element(schema-element) return "schema-element()"
     case element(query) return "cts:query"
     case element(point) return "cts:point"
     case element(string) return "xs:string"
     case element(integer) return "xs:integer"
     case element(int) return "xs:int"
     case element(long) return "xs:long"
     case element(double) return "xs:double"
     case element(decimal) return "xs:decimal"
     case element(float) return "xs:float"
     case element(boolean) return "xs:boolean"
     case element(anyURI) return "xs:anyURI"
     case element(dateTime) return "xs:dateTime"
     case element(date) return "xs:date"
     case element(duration) return "xs:duration"
     case element(dayTime) return "xs:dayTimeDuration"
     case element(yearMonth) return "xs:yearMonthDuration"
     case element(monthDay) return "xs:monthDayDuration"
     case element(reference) return "xs:string"
     default return fn:error(xs:QName("UNRESOLVED-DATATYPE"),$field)
};
(:~
 : Resolves the field to its xs:Type equivalent
 : @return - String representing the schema
 :)
declare function domain:resolve-ctstype(
    $field as element()
) {
   let $data-type := element{$field/@type}{$field}
   return 
     typeswitch($data-type)
     case element(uuid) return "xs:string"
     case element(identity) return "xs:string"
     case element(create-timestamp) return "xs:dateTime"
     case element(create-user) return "xs:string"
     case element(update-timestamp) return "xs:dateTime"
     case element(update-user) return "xs:string"
     case element(modify-user) return "xs:string"
     case element(binary) return "binary()"
     case element(schema-element) return "schema-element()"
     case element(query) return "cts:query"
     case element(point) return "cts:point"
     case element(string) return "xs:string"
     case element(integer) return "xs:integer"
     case element(int) return "xs:int"
     case element(long) return "xs:long"
     case element(double) return "xs:double"
     case element(decimal) return "xs:decimal"
     case element(float) return "xs:float"
     case element(boolean) return "xs:boolean"
     case element(anyURI) return "xs:anyURI"
     case element(dateTime) return "xs:dateTime"
     case element(date) return "xs:date"
     case element(duration) return "xs:duration"
     case element(dayTime) return "xs:dayTimeDuration"
     case element(yearMonth) return "xs:yearMonthDuration"
     case element(monthDay) return "xs:monthDayDuration"
     case element(reference) return "xs:string"
     default return fn:error(xs:QName("UNRESOLVED-DATATYPE"),$field)
};

(:~
 : Returns the default application domain content-namespace-uri 
 : @return the content-namespace for the default application
 :)
declare function domain:get-content-namespace-uri(
) as xs:string 
{
  domain:get-content-namespace-uri(config:default-application())
};

(:~
 : Returns the content-namespace value for a given application
 : @param $application-name - name of the application
 : @return - The namespace URI of the given application
 :)
declare function domain:get-content-namespace-uri( 
   $application-name as xs:string
) as xs:string 
{
   let $key := fn:concat($application-name, ":namespace-uri")
   let $cache := domain:get-identity-cache($key)
   return
     if($cache) 
     then $cache
     else 
        let $value := fn:data(config:get-domain($application-name)/domain:content-namespace/@namespace-uri)
        return (
            domain:set-identity-cache($key,$value),
            $value
        )
};

(:~
 : Gets the controller definition for a given application by its name
 : @param $application-name - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller(
   $application-name as xs:string,
   $controller-name as xs:string
) as element(domain:controller)? 
{
    let $domain := config:get-domain($application-name)
    return 
        $domain/domain:controller[@name eq $controller-name]  
};
(:~
 : Returns the actions associated with the controller. The function assumes the controller lives in the default application.
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $controller-name as xs:string
) {
  domain:get-controller-actions(config:default-application(),$controller-name)
};

(:~
 : Returns all the available functions for a given controller. 
 : @param $application-name - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $application-name as xs:string,
  $controller-name as xs:string
) {
    let $controller := domain:get-controller($application-name,$controller-name)
    let $base-uri := config:application-directory($application-name)
    let $base-ns  := config:application-namespace($application-name)
    let $controller-ns := fn:concat($base-ns,"/controller/",$controller-name)
    let $stmt := fn:concat(
        "import module namespace controller = 'http://xquerrail.com/controller/base' at '/_framework/base/base-controller.xqy'; ",
        "&#xA;xdmp:functions()[fn:namespace-uri-from-QName(fn:function-name(.)) = 'http://xquerrail.com/controller/base']"
        )
    let $functions := try { 
        xdmp:eval($stmt)
     } catch($ex) {
        fn:error(xs:QName("CONTROLLER-FUNCTIONS-ERROR"),"Error Retrieving functions",
          $stmt)
     }
    return
    fn:distinct-values(for $func in $functions
    let $name := fn:local-name-from-QName(fn:function-name($func))
    where fn:function-arity($func) = 0
    return 
       $name
    )
};
(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application-name - Name of the application
 :  @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-model(
    $controller-name as xs:string
) as element(domain:model)?
{
   domain:get-controller-model(config:default-application(),$controller-name)
};

(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application-name - Name of the application
 :  @param $controller-name - Name of the controller
 :  @return  - returns the model associated with the given controller.
 :)
declare function domain:get-controller-model(
    $application-name as xs:string, 
    $controller-name as xs:string
) as element(domain:model)?
{
     let $domain := config:get-domain($application-name)
     let $controller := domain:get-controller($application-name,$controller-name)
     let $model := domain:get-domain-model(fn:data($controller/@model))
     return 
        $model
};

(:~
 : Gets the name of the controller associated with a model
 : @param $model-name - name of the model
 : @return The name of the controller 
 :)
declare function domain:get-model-controller-name(
    $model-name as xs:string
 ) as xs:string* {
    domain:get-model-controller(domain:get-default-application(),$model-name)
};
(:~
 : Gets the name of the controller for a given application and model.
 :  @param $application-name - Name of the application
 :  @param $model-name - Name of the controller
 :  @return - the name of the controller
 :)
declare function domain:get-model-controller-name(
    $application as xs:string, 
    $model-name as xs:string
 ) as xs:string* {
    let $domain := config:get-domain($application)
    return
        fn:data($domain/domain:controller[@model = $model-name]/@name)
};

(:~
 : Returns a domain model from the default domain
 : @deprecated
 : @param - returns a domain model given a
 :)
declare function domain:get-domain-model($model-name as xs:string*) {
    domain:get-domain-model(config:default-application(), $model-name)
};
(:~
 : Returns a domain model from an application by its name
 : @param $application - Name of the application
 : @param $domain-name - Name of the domain model
 :)
declare function domain:get-domain-model(
    $application as xs:string, 
    $domain-name as xs:string*
) as element(domain:model)*
{
  let $domain := config:get-domain($application)
  let $models := 
     for $modelName in $domain-name
     let $cache-key := fn:concat($application, ":" ,$modelName)
     let $cached := domain:get-model-cache($cache-key)
     return
        if($cached) then $cached
        else 
          let $model := $domain/domain:model[@name eq $modelName]
          let $extends := 
              if($model/@extends) then
                  let $extendedDomain := $domain/domain:model[@name eq fn:data($model/@extends)]
                  return
                      element { fn:node-name($model) } {
                         $model/@*,
                         for $f in  $extendedDomain/(domain:element | domain:container | domain:attribute)
                         return 
                            element { fn:node-name($f) } {
                                if($f/@namespace) 
                                then $f/@namespace
                                else $extendedDomain/@namespace                            
                                , $f/@*[. except $f/@namespace] 
                                , $f/node()
                            }
                        , $model/node()
                     }
            else $model
         return ($extends,domain:set-model-cache($cache-key,$extends))
    return element domain:domain { $domain/@*, $domain/domain:name, $domain/*[. except $domain/domain:model], $models } / domain:model
};
(:~
 : Returns a list of all defined controllers for a given application domain
 : @param $application-name - application domain name
 :)
declare function domain:get-controllers(
   $application-name as xs:string
){
   config:get-domain($application-name)/domain:controller
};

(:~
 : Returns the default application domain defined in the config.xml
 :)
declare function domain:get-default-application(){
    config:default-application()
};

(:~
 : Returns the default content namespace for a given application. Convenience wrapper for @see config:default-namespace() function.
 : @param $application-name - Name of the application 
 : @return default content namespace
 :)
declare function domain:get-default-namespace(
$application-name as xs:string
) {
    let $application := config:get-domain($application-name)
    return 
       $application/domain:content-namespace
};

(:~
 : Returns all content and declare-namespace in application-domain
 : @param $application-name - Name of the application 
 : @return sequence of element(namespace).
 :)
declare function domain:get-domain-namespaces(
  $application-name as xs:string
)  as element(namespace) {
    let $application := config:get-domain($application-name)
    for $ns in $application/(domain:content-namespace | domain:declare-namespace)
    return 
       <namespace prefix="{$ns/@prefix}" namespace="{$ns/(@namespace|@namespace-uri)}"/>
};

(:~
 : Returns a list of models with a given class attribute from a given application.  
 : Function is helpful for selecting a list of all models or selecting them by their @class attribute.
 : @param $application-name - Name of the application
 : @param $class - the selector class it can be space delimitted
 :)
declare function domain:model-selector( 
   $application-name as xs:string,
   $class as xs:string*
) as element(domain:model)*
{ 
   let $domain := config:get-domain($application-name)
   return
       $domain/domain:model[@class = $class ! fn:tokenize(.,"\s+")]
};

(:~
 : Returns a list of domain models given a class selector
 : @param $class - name of a class associated witha given model. 
 :)
declare function domain:model-selector( 
   $class as xs:string
) as element(domain:model)*
{ 
  domain:model-selector(config:default-application(),$class)
};

(:~
 : Returns the unique hash of an element suitable for creating a named element.
 :)
declare function domain:get-field-key(
  $node as node()
) {
   domain:get-field-id($node)
};

(:~
 : Returns the name key path defined. The name key is a simplified notation that concatenates all the names - the modelname with .
 : (ex.  <b>Customer.Address.Line1)</b>.  This is useful for creating ID field in an html form.
 : @param $field - Field in a <b>domain:model</b>
 :)
declare function domain:get-field-name-key($field as node()) {
    let $items := $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-NODE-FIELDS]
    let $ns := domain:get-field-namespace($field)
    let $path := 
    fn:string-join(
        for $item in $items
        return  fn:concat($item/@name)
        ,"."
    )
    return $path
};

(:~
 :  Returns a unique identity key that can used as a unique identifier for the field.
 :  @param $context - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-id($context as node()) {
    let $items := $context/ancestor-or-self::*[fn:node-name($context) = $DOMAIN-FIELDS]
    let $ns := domain:get-field-namespace($context)
    let $path := 
    fn:string-join(
        for $item in $items
        return
            fn:concat("{" , $ns, "}", $item/@name)
        ,"/"
    )
    return 
    fn:concat($context/@name,"__", xdmp:md5($path))
};

(:~
 :  Gets the namespace of the field. Namespace resolution is inherited if not specified by the field in the following order:
 :  field-> model-> domain:content-namespace
 :  @param $field - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-namespace(
$field as node()
) as xs:string?
{
    let $key   := xs:string(xdmp:hash64($field))
    let $cache := domain:get-identity-cache($key)
    return
    if($cache) then $cache
    else 
    let $field-namespace := fn:head(
        if($field/(@namespace-uri|@namespace) )
        then $field/(@namespace-uri|@namespace)/fn:string()
        else if($field/ancestor::domain:model/(@namespace-uri|@namespace))
        then $field/ancestor::domain:model/(@namespace-uri|@namespace)/fn:string()
        else if($field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|text()))
        then $field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|/text())
        else (domain:get-content-namespace-uri(),"")
    )
    return (
        domain:set-identity-cache($key,$field-namespace),
        $field-namespace
    )
};

(:~
 : Retrieves the value of a field based on a parameter key
 : @param $field - The field definition representing the value to return
 : @param $params - A map:map representing the field parameters
:)
declare function domain:get-field-param-value(
    $field as element(),
    $params as map:map) {
  let $key := domain:get-field-id($field)
  let $name-key := domain:get-field-name-key($field)
  let $key-value := map:get($params,$key)
  let $name-value := map:get($params,$field/@name)
  let $namekey-value := map:get($params,$name-key)
  return
    if($key-value) then $key-value else if($namekey-value) then $namekey-value else $name-value
};

(:~
 : Gets the value of the field from a given field definition.  
 : @field - field instance of type(element|attribute|container)
 : @current-node - is the element from which to extract the value from.
 :)
declare function domain:get-field-value(
    $field as element(),
    $current-node as node()?
 ) as item()* {
    domain:get-field-value($field,domain:get-field-id($field),$current-node)    
};

(:~
 : Returns the field value from a given model instance
 : @param $field - the model definition
 : @param $key   - The key associated with a given element as assigned by domain:get-field-name
 : @param $current-node - is the instance of the current element to extract the value from
 :)
declare function domain:get-field-value(
   $field as element(), 
   $key as xs:string, 
   $current-node as node()?
) {
    if($current-node) then 
         let $xpath := domain:get-field-xpath($field,$key)
         let $value :=       
             if($xpath) 
             then try{ xdmp:value(fn:concat("$current-node",$xpath))} catch($ex){xdmp:log($ex)}
             else ()
         return 
             if($field/@type eq "reference") 
             then $value
             else $value
     else ()
};

(:~
 : Returns the reference value from a given field from the current context node.
 : @param $field - the model definition
 : @param $current-node - is the instance of the current element to extract the value from
 :)
declare function domain:get-field-reference(
    $field as element(),
    $current-node as node()
 ){
    domain:get-field-value($field,domain:get-field-id($field),$current-node)/@ref-id
};

(:~
 : Retrieve the reference context associated with a reference field. 
 :   model:{$model-name}:{function}<br/>
 :   application:{scope}:{function}<br/>
 :   optionlist:{application}:{name}<br/>
 :   lib:{library}:{function}<br/>
 : @param $field - Field element (domain:element) 
 :)
declare function domain:get-field-reference-model(
    $field as element()
) {
    let $reference := $field/@reference
    let $tokens    := fn:tokenize($reference,":")
    let $scope     := $tokens[1]
    let $ref       := $tokens[2]
    let $action    := $tokens[3]
    return
        switch($scope)
          case "model" return domain:get-model($ref)
          case "application" return ()
          default return ()
        
};
(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain:get-field-xpath($field) {
  domain:get-field-xpath($field/ancestor::domain:model, domain:get-field-id($field))
};

(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $model - The model/field representing the field.
 : @param $key - The name of the field as a string value
 :)
declare function domain:get-field-xpath(
  $model as element(), 
  $key as xs:string
) { 
     domain:get-field-xpath($model, $key, 2)  
};

(:~
 : Returns the xpath expression based on the current level of the context node
 : @param model - 
 : @param $key  - is the id/name key assigned to the field.
 : @param $level - Number of parent levels to traverse for xpath expression. 
 :)
declare function domain:get-field-xpath($model, $key, $level) { 
     let $elementField := (
      $model/descendant-or-self::*[fn:node-name(.) = $DOMAIN-NODE-FIELDS][$key = domain:get-field-id(.)],
      domain:get-field-from-dotted-path($model, $key)
     )[1]
     (:let $level := if($elementField instance of element(domain:attribute)) then 1 else $level:)
     let $ns := domain:get-field-namespace($model) 
     let $path := 
        fn:string-join(
        for $chain in ($elementField/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-FIELDS])[$level to fn:last()]
        return
           if($chain instance of element(domain:element))
           then fn:concat("*:",$chain/@name)
           else if($chain instance of element(domain:attribute)) 
           then fn:concat("@",$chain/@name)
           else if($chain instance of element(domain:container))
           then fn:concat("*:",$chain/@name)
           else ()
        , "/")

    return 
        if(fn:normalize-space($path) eq "") 
        then () 
        else fn:concat("/",$path)
};
(:~
 : Constructs a map of a domain instance based on a list of retain node names
 : @param $doc - context node instance
 : @param $retain  - a list of nodes to retain from original context
 :)
declare function domain:build-value-map($doc as node()?,$retain as xs:string*) 
as map:map?
{
  let $map := map:map()
  let $results :=  domain:recurse($doc,$map,$retain)
  return
    $results
};

(:~
 : Recursively constructs a map of a domain instance based on a list of retain node names. This allows for building 
 : compositions of existing domains or entirely new domain objects
 : @param $doc - context node instance
 : @param $map  - an existing map to populate with.
 : @param $retain  - a list of nodes to retain from original context
 :)
declare private function domain:recurse(
  $node as node()?,
  $map as map:map, 
  $retain as xs:string*) {
  let $key := domain:get-field-id($node)
  let $_ :=
    typeswitch ($node) 
    case document-node() return domain:recurse($node/node(),$map,$retain)
    case text() return 
        if(fn:string-length($node) > 0) then
            let $key := domain:get-field-id($node/..) 
            return map:put($map, $key, (map:get($map,$key), $node))
        else ()
    case element() return 
         if($node/(element()|attribute()) and fn:not(fn:local-name($node) = $retain)) 
         then 
           for $n in $node/(element()|attribute()| text())
           return domain:recurse($n,$map,$retain)
         else 
           let $value := $node/node()
           return map:put($map, $key,(map:get($map,$key),$value))
    case attribute() return 
      map:put($map, $key,(map:get($map,$key),fn:data($node)))
    default return ()
 return $map
};
(:@deprecated:)
declare function domain:get-model-by-xpath(
    $path as xs:string
) as xs:string?
{

    let $domain := config:get-domain(config:default-application())
    let $subpath :=
    fn:string-join(
        for $item at $pos in fn:tokenize($path, "/")[2 to fn:last()]
        let $item := 
          (: Remove any namespace bindings since we are finding :)
          (: the content in the application domain :)
          if(fn:contains($item, ":"))
          then fn:tokenize($item, ":")[fn:last()]
          else $item
          
        let $item := 
          (: Drop attributes since we are finding it in the domain :)
          if(fn:starts-with($item, "@")) 
          then fn:substring($item, 2)
          else $item
         return 
        fn:concat('*[@name ="', $item, '"]')
     , "/")    
    let $xpath := if ($subpath) then fn:concat( "/", $subpath) else ()
    let $key := 
        if($xpath) then 
            let $stmt := fn:string(<stmt>$domain{$xpath}</stmt>)
            let $domain-node :=  xdmp:value($stmt)
            return domain:get-field-id($domain-node)
        else ()
    
    return $key
};

declare function domain:get-field-value-from-dotted-path($model as element(domain:model), $name as xs:string, $instance as node()?) as element()? {
  domain:get-field-value(domain:get-field-from-dotted-path($model, $name), $instance)
};

declare function domain:get-field-from-dotted-path($field as element(), $name as xs:string) as element()? {
  if (fn:contains($name, '.')) then
    let $parent := fn:substring-before($name, '.')
    let $new := $field/descendant-or-self::*[fn:node-name(.) = $domain:DOMAIN-NODE-FIELDS][$parent = ./@name]
    return
    if ($new) then
      domain:get-field-from-dotted-path($new, fn:substring-after($name, '.'))
    else
      ()
  else
    $field/descendant-or-self::*[fn:node-name(.) = $domain:DOMAIN-NODE-FIELDS][$name = ./@name]
};

(:~
 : Returns a controller based on the model name
 : @param $model-name  - name of the model
 :)
declare function domain:get-model-controller( $model-name) {
    domain:get-model-controller(config:default-application(),$model-name)
};

(:~
 : Returns a controller based on the model name
 : @param $application - name of the application
 : @param $model-name  - name of the model
 :)
declare function domain:get-model-controller($application, $model-name) as element(domain:controller){
    let $domain := config:get-domain(config:get-application($application))
    return 
        if($domain) then $domain/domain:controller[@model = $model-name]
        else fn:error(xs:QName("INVALID-DOMAIN"),"Invalid domain", $application)
};
(:~
 : Returns the model definition by its application and model name
 : @param $application-name - Name of the application
 : @param $model-name - Name of the model
 : @return  a model definition
  ~:)
declare function domain:get-model(
$application-name as xs:string,
$model-name as xs:string*
) as element(domain:model)* {
   domain:get-domain-model($application-name,$model-name)
};
(:~
 : Returns a model based by its name(s)
 : @param $model-name - list of model names to return 
 :)
declare function domain:get-model(
  $model-name as xs:string*
) as element(domain:model)* {
   domain:get-domain-model($model-name)
};

(:~
 : Returns an optionlist from the default domain
 : @param $name  Name of the optionlist
 :)
declare function domain:get-optionlist($name) {
    domain:get-optionlist(domain:get-default-application(),$name)
};

(:~
 :  Returns an optionlist from the application by its name
 : @param $application-name  Name of the application
 : @param $listname  Name of the optionlist
 :)
declare function domain:get-optionlist($application-name,$listname) {
    config:get-domain($application-name)/domain:optionlist[@name eq $listname]
};

(:~
 : Returns an optionlist associated with a field definitions inList attribute. 
 : @param $field  Field instance (domain:element|domain:attribute)
 : @return optionlist specified by field.
 :)
declare function domain:get-field-optionlist($field) {
   (
      $field/ancestor::domain:model/domain:optionlist[$field/domain:constraint/@inList = @name],
      $field/ancestor::domain:domain/domain:optionlist[$field/domain:constraint/@inList = @name],
      $field/domain:constraint/@inList
   )[1]
};
(:~
 : Gets an application element specified by the application name
 : @param $application Name of the application
 :)
declare function domain:get-application($application) {
   config:get-application($application)
};
(:~
 : Returns the key that represents the given model
 : the key format is model:{model-name}:reference
 : @param $domain-model - The instance of the domain model
 : @return The reference-key defining the model
 :)
declare function domain:get-model-reference-key(
  $domain-model as element(domain:model)
) {
   fn:concat("model:",$domain-model/@name,":reference")
}; 
(:~
 : Gets a list of domain models that reference a given model.
 : @param $domain-model - The domain model instance.
 : @return a sequence of domain:model elements
 :)
declare function domain:get-model-references(
    $domain-model as element(domain:model)
) {
    let $domain := config:get-domain($domain-model/ancestor::domain:domain/domain:name)
    let $reference-key := domain:get-model-reference-key($domain-model)
    let $reference-models := 
        $domain/domain:model
        (:[//cts:element/@reference = $reference-key]:)
        [cts:contains(.,
            cts:element-attribute-value-query(
                xs:QName("domain:element"),
                xs:QName("reference"),
                $reference-key)
        )]
    return
      $reference-models
};

(:~
 : Returns true if a model is referenced by its identity
 : @param $domain-model - The model to determine the reference
 : @param $instance - 
 :)
declare function domain:is-model-referenced(
 $domain-model as element(domain:model),
 $instance as element()
 ) as xs:boolean {
     let $reference-key    := domain:get-model-reference-key($domain-model)
     let $reference-models := domain:get-model-references($domain-model)
     let $reference-values := (
        domain:get-field-value(domain:get-model-key-field($domain-model),$instance),
        domain:get-field-value(domain:get-model-keyLabel-field($domain-model),$instance)
     )
     let $reference-query := 
       cts:or-query((
        for $reference-model in $reference-models
        let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
        return
          domain:get-model-reference-query($reference-model,$reference-key,$reference-values)
       ))
     return 
        xdmp:exists(cts:search(fn:collection(),$reference-query))  
  };
  
(:~
 : Returns true if a model is referenced by its identity
 : @param $domain-model - The model which is the base of the instance reference
 : @instance - The instance for a given model
 :)
declare function domain:get-model-reference-uris(
 $domain-model as element(domain:model),
 $instance as element()
 ) {
     let $reference-key    := domain:get-model-reference-key($domain-model)
     let $reference-models := domain:get-model-references($domain-model)
     let $reference-values := (
        domain:get-field-value(domain:get-model-key-field($domain-model),$instance),
        domain:get-field-value(domain:get-model-keyLabel-field($domain-model),$instance)
     )
     let $reference-query := 
       cts:or-query((
        for $reference-model in $reference-models
        let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
        return
          domain:get-model-reference-query($reference-model,$reference-key,$reference-values)
       ))
     return cts:uris((),(),$reference-query)
};
  
  
(:~
 : Creates a query that determines if a given model instance is referenced by any model instances.
 : The query is built by traversing all models that have a reference field that is referenced by 
 : the given instance value.
 : @param $reference-model - The model that is the base for the reference
 : @param reference-key  - The key to match the reference against the key is model:{model-name}:reference
 : @param reference-value - The value for which the query will match the reference
 :)
declare function domain:get-model-reference-query(
    $reference-model as element(domain:model),
    $reference-key as xs:string,
    $reference-value as xs:anyAtomicType*
 ) {
    let $referenced-fields := $reference-model//domain:element[@type = "reference" and @reference = $reference-key]
    let $base-constraint :=
        switch($reference-model/@persistence)
           case "directory" return cts:directory-query($reference-model/domain:directory,"infinity")
           case "document" return cts:document-query($reference-model/domain:document)
           case "singleton" return cts:document-query($reference-model/domain:document)
           default return fn:error(xs:QName("PERSISTENCE-NOT-QUERYABLE"),"Cannot query against persistence",$reference-model/@persistence)
    return 
      cts:and-query((
        $base-constraint,
        for $reference-field in $referenced-fields
        let $field-ns := domain:get-field-namespace($reference-field)
        let $field-name := fn:data($reference-field/@name)
        return 
          cts:or-query((
            cts:element-attribute-value-query(fn:QName($field-ns,$field-name),xs:QName("ref-uuid"),$reference-value)
          ))
      ))
 };

(:~
 : Returns the default collation for the given field. The function walks up the ancestor tree to find the collation in the following order:
 : $field/@collation->$field/model/@collation->$domain/domain:default-collation.
 : @param $field - the field to find the collation by.
 :)
declare function domain:get-field-collation($field as element()) as xs:string {
   (:fn:head(($field/@collation,
    $field/ancestor::domain:model/@collation,
    $field/ancestor::domain:domain/domain:default-collation,
   "http://marklogic.com/collation/codepoint"
   )):)
   if($field/@collation) then $field/@collation
   else if($field/ancestor::domain:model/@collation) then $field/ancestor::domain:model/@collation
   else if($field/ancestor::domain:domain/domain:default-collation) then $field/ancestor::domain:domain/domain:default-collation
   else fn:error(xs:QName("COLLATION-ERROR"), "No collation defined for domain")
};

(:~
 : Returns the list of fields that are part of the uniqueKey constraint as defined by the $model/@uniqueKey attribute.
 : @param $model - Model that defines the unique constraint.
 :)
declare function domain:get-model-uniqueKey-constraint-fields($model as element(domain:model)) {
if($model/@uniqueKey and $model/@uniqueKey ne "") 
   then
     let $fields := fn:tokenize($model/@uniqueKey," ") ! fn:normalize-space(.)
     for $f in $fields
     let $field := $model//(domain:element|domain:attribute)[@name = $f]
     return
       if($field) then $field else fn:error(xs:QName("UNIQUEKEY-FIELD-MISSING"),"The key in a uniqueKey constraint is missing",$f)     
   else () 
};
(:~
 : Returns a unique constraint query 
 :)
declare function domain:get-model-uniqueKey-constraint-query(
    $model as element(domain:model),
    $params as map:map,
    $mode as xs:string
) {
   if(domain:get-model-uniqueKey-constraint-fields($model)) then 
       let $id-field := domain:get-model-identity-field($model)
       let $id-field-key := domain:get-field-id($id-field)
       let $id-value := domain:get-field-param-value($id-field,$params)
       let $id-query := 
          if($mode = ("create","new")) then
               if($id-value) then 
                 typeswitch($id-field)
                   case element(domain:element) return
                        cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                   case element(domain:attribute) return
                        cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                   default return ()
                else ()
            else 
             typeswitch($id-field)
                  case element(domain:element) return
                    cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"!=",$id-value,("collation="  || domain:get-field-collation($id-field)))
                  case element(domain:attribute) return
                       cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"!=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                  default return ()
     let $unique-fields := domain:get-model-uniqueKey-constraint-fields($model)
     let $constraint-query := 
          for $field in $unique-fields
          let $field-value := domain:get-field-param-value($field,$params)
          let $field-ns := domain:get-field-namespace($field)
          return 
           typeswitch($field)
           case element(domain:attribute) return
              let $parent := $field/parent::domain:element
              let $parent-ns := domain:get-field-namespace($parent)
              return
               cts:element-attribute-value-query(fn:QName($parent-ns,$parent/@name),xs:QName($field/@name),$field-value)
           case element(domain:element) return
              switch($field/@type)
                 case "reference" return 
                   cts:or-query((
                       cts:element-attribute-value-query(fn:QName($field-ns,$field/@name),xs:QName("ref-id"),$field-value),
                       cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)  
                   ))
                 default return 
                   cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)
           default return ()                
     let $search-expression := domain:get-model-search-expression($model,cts:and-query(($id-query,$constraint-query)))
     return
        xdmp:eval($search-expression)
   else ()
};
(:~
 : Returns the value of a query matching a unique constraint. A unique constraint at a field level is defined
 : that every value that is considered unique be unique for each field.  For compound unique values 
 : use @see uniqueKey
 : @param $model  - The model to generate the unique constraint
 : @param $params - The map:map of parameters.
 : @param $mode   - The $mode can either be "create" or "update". When in update mode, 
                    removes the document under update to ensure it does not assume it is part of the query.
 :)
declare function domain:get-model-unique-constraint-query($model as element(domain:model),$params as map:map,$mode as xs:string) {
   if(domain:get-model-unique-constraint-fields($model)) then 
     let $id-field := domain:get-model-identity-field($model)
     let $id-field-key := domain:get-field-id($id-field)
     let $id-value := domain:get-field-param-value($id-field,$params)
     let $id-query := 
        if($mode = "create") then
          if($id-value) then 
              typeswitch($id-field)
                case element(domain:element) return
                  cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                case element(domain:attribute) return
                     cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                default return ()
              else ()
          else if($id-value) then 
              typeswitch($id-field)
                case element(domain:element) return
                  cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"!=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                case element(domain:attribute) return
                     cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"!=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                default return ()
              else ()
     let $unique-fields := domain:get-model-unique-constraint-fields($model)
     let $constraint-query := 
        for $field in $unique-fields
        let $field-value := domain:get-field-param-value($field,$params)
        let $field-ns := domain:get-field-namespace($field)
        return 
         typeswitch($field)
         case element(domain:attribute) return
            let $parent := $field/parent::domain:element
            let $parent-ns := domain:get-field-namespace($parent)
            return
             cts:element-attribute-value-query(fn:QName($parent-ns,$parent/@name),xs:QName($field/@name),$field-value)
         case element(domain:element) return
            switch($field/@type)
               case "reference" return 
                  cts:element-attribute-value-query(fn:QName($field-ns,$field/@name),xs:QName("ref-id"),$field-value)
               default return 
                 cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)
         default return ()                
     let $search-expression := domain:get-model-search-expression($model,cts:and-query(($id-query,cts:or-query($constraint-query))))
     return
          xdmp:eval($search-expression)
 else ()
};

(:~
 : Constructs a search expression based on a give model
 :)
declare function domain:get-model-search-expression($domain-model as element(domain:model),$query as cts:query?)
{
 domain:get-model-search-expression($domain-model,$query,())
};

(:~
 : Constructs a search expression based on a givem model
 :)
declare function domain:get-model-search-expression(
    $domain-model as element(domain:model),
    $query as cts:query?,
    $options as xs:string*) {
  let $pathExpr := switch($domain-model/@persistence)
    case "document" return
       "fn:doc('" || $domain-model/domain:document || "')/ns0:" || $domain-model/domain:document/@root || "/ns0:" || $domain-model/@name
    case "directory" return
       "fn:collection()" || "/ns0:" || $domain-model/@name
    default return 
       "cts:element-query(xs:QName('ns0:" || $domain-model/@name || "'),cts:and-query(()))"
  let $baseQuery := 
    switch($domain-model/@persistence)
       case "document" return cts:document-query($domain-model/domain:document)
       case "singleton" return cts:document-query($domain-model/domain:document)
       case "directory" return cts:directory-query($domain-model/domain:directory)
       default return ()
  
  let $searchExpr := 
       "cts:search(" || $pathExpr || "," || xdmp:describe(cts:and-query(($baseQuery,$query)),(),()) || "," || xdmp:describe($options,(),()) || ")"
  let $nsExpr := "declare namespace ns0 = '" || domain:get-field-namespace($domain-model) || "'; "
  let $expr :=  $nsExpr || $searchExpr  
  return
         $expr
};

(:~
 : Constructs a xdmp:estimate expresion for a referenced model
 : @param $domain-model - model definition
 : $query - Additional query to add the estimate expression
 : $options - cts:search options   
 :)
declare function domain:get-model-estimate-expression(
    $domain-model as element(domain:model),
    $query as cts:query?,
    $options as xs:string*
) {
  let $persistence := fn:data($domain-model/@persistence)
  let $_check := 
     if(fn:not($persistence = ("document","directory","singleton")))
     then fn:error(xs:QName("MODEL-EXPRESSION-ERROR"),"Cannot construct a query when persistence not set",fn:data($domain-model/@persistence))
     else ()     
  let $pathExpr := switch($domain-model/@persistence)
    case "document" return
       "fn:doc('" || $domain-model/domain:document || "')/ns0:" || $domain-model/domain:document/@root || "/ns0:" || $domain-model/@name
    case "directory" return
       "fn:collection()" || "/ns0:" || $domain-model/@name
    default return 
       "cts:element-query(xs:QName('ns0:" || $domain-model/@name || "'),cts:and-query(()))"
  let $baseQuery := 
    switch($domain-model/@persistence)
       case "document" return cts:document-query($domain-model/domain:document)
       case "singleton" return cts:document-query($domain-model/domain:document)
       case "directory" return cts:directory-query($domain-model/domain:directory)
       default return fn:error(xs:QName("MODEL-EXPRESSION-ERROR"),"Cannot construct a query when persistence not set",fn:data($domain-model/@persistence))  
  let $searchExpr := 
       "xdmp:estimate(cts:search(" || $pathExpr || "," || xdmp:describe(cts:and-query(($baseQuery,$query)),(),()) || "," || xdmp:describe($options,(),()) || "))"
  let $nsExpr := "declare namespace ns0 = '" || domain:get-field-namespace($domain-model) || "'; "
  let $expr :=  $nsExpr || $searchExpr  
  return
      $expr
};

(:~
 : Fires an event and returns if event succeeded or failed
 : It is important to note that any event that is fired must return
 : the number of values associated with the given function.
 : Events that break this convention will lead to spurious results
 : @param $model - the model for which the event should fire
 : @param $event-name - The name of the event to fire
 : @param $context - The context for the given event in most cases
 :                   the context is a map:map if it is for before-event
 :)
declare function domain:fire-before-event(
    $model as element(domain:model),
    $event-name as xs:string,
    $context as item()*
) {
   let $event := $model/domain:event[@name = $event-name and @mode= ("before","wrap")]
   return
   if($event) then 
   let $module := $event/@module
   let $module-namespace := $event/@module-namespace
   let $module-uri := $event/@module-uri
   let $function := $event/@function
   let $call := xdmp:function(fn:QName($module-namespace,$function),$module-uri)
   return
     xdmp:apply($call,$event,$context)
   else $context
};

(:~
 : Fires an event and returns if event succeeded or failed.
 : It is important to note that any event that is fired must return
 : the number of values associated with the given function.
 : Events that break this convention will lead to spurious results
 : @param $model - the model for which the event should fire
 : @param $event-name - The name of the event to fire
 : @param $context - The context for the given event in most cases
 :                   the context is an instance of the given model.
 :)
declare function domain:fire-after-event(
    $model as element(domain:model),
    $event-name as xs:string,
    $context as item()*
) {
   let $event := $model/domain:event[@name = $event-name and @mode= ("after","wrap")]
   return
   if($event) then 
     let $module := $event/@module
     let $module-namespace := $event/@module-namespace
     let $module-uri := $event/@module-uri
     let $function := $event/@function
     let $call := xdmp:function(fn:QName($module-namespace,$function),$module-uri)
     return
       xdmp:apply($call,$event,$context)
   else $context
};