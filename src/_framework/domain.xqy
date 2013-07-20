xquery version "1.0-ml";
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and 
 : definitions for dynamic features built into XQuerrail.
 : @version 2.0
 :)
module namespace domain = "http://www.xquerrail-framework.com/domain";

import module namespace config = "http://www.xquerrail-framework.com/config"
at "/_framework/config.xqy";

declare variable $DOMAIN-FIELDS := 
   for  $fld in ("domain:model","domain:container","domain:element","domain:attribute") 
   return  xs:QName($fld);
   
declare variable $DOMAIN-NODE-FIELDS := 
   for  $fld in ("domain:container","domain:element","domain:attribute") 
   return  xs:QName($fld);

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
  $model//(domain:element|domain:attribute)[@identity eq "true" or @type eq "identity"]
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-key-field($model as element(domain:model)) {
  $model//(domain:element|domain:attribute)[$model/@key = @name]
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keyLabel-field($model as element(domain:model)) {
  $model//(domain:element|domain:attribute)[$model/@keyLabel = @name]
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
 :)
declare function domain:resolve-datatype($field)
{
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
declare function domain:resolve-ctstype($field)
{
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
   fn:data(config:get-domain($application-name)/domain:content-namespace/@namespace-uri)
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
 :  Returns the name of the model associated with a controller.
 :  @param $application-name - Name of the application
 :  @param $controller-name - Name of the controller
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
 : @param - $model-name as xs:string
 : @return  - The name of the controler 
 :)
declare function domain:get-model-controller-name(
    $model-name as xs:string
 ) as xs:string* {
    domain:get-model-controller(domain:get-default-application(),$model-name)
};
(:~
 : Gets the name of the controller for a given application and model.
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
declare function domain:get-domain-model($model-name as xs:string) {
    domain:get-domain-model(config:default-application(), $model-name)
};
(:~
 : Returns a domain model from an application by its name
 : @param $application - Name of the application
 : @param $domain-name - Name of the domain model
 :)
declare function domain:get-domain-model($application as xs:string, $domain-name as xs:string*)  
as element(domain:model)*
{
  let $domain := config:get-domain($application)
  let $models := 
    for $modelName in $domain-name
    let $model := $domain/domain:model[@name=$domain-name]
    return
        if($model/@extends) then
            let $extendedDomain := $domain/domain:model[@name = fn:data($model/@extends)]
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
    return $models
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
 : Returns the default content namespace for a given application
 :)
declare function domain:get-default-namespace(
$application-name as xs:string
) {
    let $application := config:get-domain($application-name)
    return 
       $application/domain:content-namespace
};

(:~
 : Returns a listing of all inscope namespaces and their
 : prefixes
 :)
declare function domain:get-in-scope-namespaces(
$application-name as xs:string
) as element(namespace)
{
  ()   
};
(:~
 : Returns all content and declare-namespace in application-domain
 : @param $application-name - Name of the application 
 :)
declare function domain:get-namespaces($application-name as xs:string) {
    let $application := config:get-domain($application-name)
    return 
    $application/(domain:content-namespace | domain:declare-namespace)
};
(:~
 : Returns a list of models with a given class attribute from a given application.  
 : Function is helpful for selecting a list of all models
 :)
declare function domain:model-selector( 
   $application-name as xs:string,
   $class as xs:string
) as element(domain:model)*
{ 
   let $domain := config:get-domain($application-name)
   return
       $domain/domain:model[@class eq $class]
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
 : Creates a unique hashed for a field
 :)
declare function domain:get-node-key($node as node()) {
    let $items := $node/(ancestor-or-self::attribute() | ancestor-or-self::*)
    return
        fn:concat(
         $node/@name,
         "__",
         xdmp:md5(
            fn:string-join(
            for $item in $items
            return
                xdmp:key-from-QName(fn:node-name($item))
            , "/"
         )))
};

(:~
 :  Returns the id key of a given model or field.
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
 : Gets the namespace-uri of the field
 :)
declare function domain:get-field-namespace(
$field as node()
) as xs:string?
{(
   $field/(@namespace-uri|@namespace)/fn:string(),
   $field/ancestor::domain:model/(@namespace-uri|@namespace)/fn:string(),
   $field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|/text()),
   domain:get-content-namespace-uri(),
   "")[1]
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
 :)
declare function domain:get-field-reference(
    $field as element(),
    $current-node as node()
 ){
    domain:get-field-value($field,domain:get-field-id($field),$current-node)/@ref-id
};

(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 :)
declare function domain:get-field-xpath($model, $key) { 
 domain:get-field-xpath($model, $key, 2)  
};

(:~
 : Returns the xpath expression based on the current level of the context node
 : @param model - 
 : @param $key  - is the id/name key assigned to the field.
 : @param $level - Number of parent levels to traverse for xpath expression. 
 :)
declare function domain:get-field-xpath($model, $key, $level) { 
     let $elementField := $model/descendant-or-self::*[fn:node-name(.) = $DOMAIN-NODE-FIELDS][$key = domain:get-field-id(.)]    
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
 : Constructs a map of a domain instance based on a list of retain node names
 : @param $doc - context node instance
 : @param $map  - an existing map to populate with.
 : @param $retain  - a list of nodes to retain from original context
 :)
declare function domain:recurse($node as node()?,$map as map:map, $retain as xs:string*) {
  let $key := domain:get-node-key($node)
  let $_ :=
    typeswitch ($node) 
    case document-node() return domain:recurse($node/node(),$map,$retain)
    case text() return 
        if(fn:string-length($node) > 0) then
            let $key := domain:get-node-key($node/..) 
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

declare function domain:get-key-by-model-xpath($path as xs:string) 
as xs:string?
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

(:~
 : Returns a controller based on the model name
 : @param $application - name of the application
 : @param $model-name  - name of the model
 :)
declare function domain:get-model-controller($application, $model-name) {
    let $domain := config:get-domain(config:get-application($application))
    return 
        if($domain) then $domain/domain:controller[@model = $model-name]
        else fn:error(xs:QName("INVALID-DOMAIN"),"Invalid domain", $application)
};

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
 :)
declare function domain:get-optionlist($name) {
    domain:get-optionlist(domain:get-default-application(),$name)
};

(:~
 :  Returns an optionlist from the domain given domain
 :)
declare function domain:get-optionlist($application-name,$listname) {
    config:get-domain($application-name)/domain:optionlist[@name eq $listname]
};

(:~
 : Returns an optionlist associated with a field in the given domain
 :)
declare function domain:get-field-optionlist($field) {
   (
      $field/ancestor::domain:model/domain:optionlist[$field/domain:constraint/@inList = @name],
      $field/ancestor::domain:domain/domain:optionlist[$field/domain:constraint/@inList = @name],
      $field/domain:constraint/@inList
   )[1]
};

declare function domain:get-application($application-name) {
   config:get-application($application-name)
};
    