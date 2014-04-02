xquery version "1.0-ml";
(:~
: Model : Base
: @author Gary Vidal
: @version  1.0
 :)

module namespace model = "http://xquerrail.com/model/base";

import module namespace search = "http://marklogic.com/appservices/search" at 
"/MarkLogic/appservices/search/search.xqy";

import module namespace domain = "http://xquerrail.com/domain" at
"/_framework/domain.xqy";

import module namespace config = "http://xquerrail.com/config" at
"/_framework/config.xqy";

declare namespace as = "http://www.w3.org/2005/xpath-functions";

declare default collation "http://marklogic.com/collation/codepoint";

(:Options Definition:)
declare option xdmp:mapping "false";

declare variable $binary-dependencies := map:map();
declare variable $current-identity := ();

(:~
 : Returns the current-identity field for use when instance does not have an existing identity
 :)
declare function  model:get-identity(){
  if(fn:exists($current-identity))
  then $current-identity
  else 
    let $id := model:generate-uuid()
    return 
       (xdmp:set($current-identity,$id),$id)
 };

(:~
 :Casts the value as a specific type
 :)
declare function model:cast-value($field as element(),$value as item()?)
{
   let $type := element {fn:QName("",$field/@type)} {""}
   return
     typeswitch($type) 
        case element(string)  return $value cast as xs:string?
        case element(integer) return $value cast as xs:integer
        case element(long)    return $value cast as xs:long
        case element(decimal) return $value cast as xs:decimal
        case element(double)  return $value cast as xs:double
        case element(float)   return $value cast as xs:float
        case element(boolean) return $value cast as xs:boolean
        case element(anyURI)  return $value cast as xs:anyURI
        case element(dateTime) return $value cast as xs:dateTime
        case element(date) return $value cast as xs:date
        case element(time) return $value cast as xs:time
        case element(duration) return $value cast as xs:duration
        case element(yearMonth) return $value cast as xs:gYearMonth
        case element(monthDay) return $value cast as xs:gMonthDay
        case element(identity) return $value cast as xs:string
        case element(schema-element) return $value
        default return $value
};
(:~
 : Returns if the value is castable to the given value based on the field/@type
 : @param $field Domain element (element|attribute|container)
 :)
declare function model:castable-value($field as element(),$value as item()?)
{
   let $type := element {fn:QName("",$field/@type)} {""}
   return
     typeswitch($type) 
        case element(string)  return $value castable as xs:string?
        case element(integer) return $value castable as xs:integer
        case element(long)    return $value castable as xs:long
        case element(decimal) return $value castable as xs:decimal
        case element(double)  return $value castable as xs:double
        case element(float)   return $value castable as xs:float
        case element(boolean) return $value castable as xs:boolean
        case element(anyURI)  return $value castable as xs:anyURI
        case element(dateTime) return $value castable as xs:dateTime
        case element(date) return $value castable as xs:date
        case element(time) return $value castable as xs:time
        case element(duration) return $value castable as xs:duration
        case element(yearMonth) return $value castable as xs:gYearMonth
        case element(monthDay) return $value castable as xs:gMonthDay
        case element(identity) return $value castable as xs:string
        case element(schema-element) return $value instance of element()
        case element(binary) return $value instance of binary()
        case element(query) return $value cast as cts:query?
        default return fn:true()
};

(:~
 : Generates a UUID based on the SHA1 algorithm.
 : Wallclock will be used to make the UUIDs sortable.
 : Note when calling function the call will reset the current-identity.  
 :)
declare function model:generate-uuid($seed as xs:integer?) 
as xs:string
{
  let $hash := (:Assume FIPS is installed by default:)
    if(fn:starts-with(xdmp:version(),"6"))
    then xdmp:apply(xdmp:function(xs:QName("xdmp:hmac-sha1")),"uuid",fn:string($seed))
    else xdmp:apply(xdmp:function(xs:QName("xdmp:sha1")),fn:string($seed))
  let $guid := fn:replace($hash,"(\c{8})(\c{4})(\c{4})(\c{4})(\c{12})","$1-$2-$3-$4-$5")
  return (xdmp:set($current-identity,$guid),$guid)
};

(:~
 :  Generates a UUID based on randomization function
 :)
declare function model:generate-uuid() as xs:string
{
    model:generate-uuid(xdmp:random()) 
};

(:~
 :  Builds a URI with variable placeholders
 :  @param $uri - Uri to format. Variables should be in form $(var-name)
 :  @param $model -  Model to use for reference
 :  @param $instance - Instance of asset can be map or instance of element from domain
 :)
declare function model:build-uri($uri as xs:string,$model as element(domain:model),$instance as item()) {
  let $token-pattern := "\$\((\i\c*)\)"
  let $patterns := fn:analyze-string($uri,$token-pattern)
  return 
    fn:string-join(
     for $p in $patterns/*
     return 
     typeswitch($p)
        case element(as:non-match) return $p
        case element(as:match) return 
            let $field-name := fn:data($p/*:group[@nr=1])
            let $field := $model//(domain:attribute|domain:element)[@name eq $field-name]
            let $data :=
                if($instance instance of map:map) 
                then 
                    let $field-id := domain:get-field-id($field)
                    let $id-value := map:get($instance,$field-id)
                    return
                        if($id-value) 
                        then $id-value
                        else map:get($instance,$field-name)                        
                else                 
                    if($field/@type eq "reference") 
                    then domain:get-field-reference($field,$instance)
                    else domain:get-field-value($field,$instance)
            return 
              if($data) 
              then $data 
              else if($field/@type eq "identity") then model:get-identity()
              else fn:error(xs:QName("EMPTY-URI-VARIABLE"),"URI Variables must not be empty",$field-name)
        default return ""
    ,"")
};

(:~
 : Creates a series of collections based on the existing update
 :)
declare function build-collections($collections as xs:string*,$model as element(domain:model),$instance as item()) {
   for $c in $collections
   return
      model:build-uri($c,$model,$instance)
};

(:~
: This function accepts a doc node and converts to an element node and 
: returns the first element node of the document
: @param - $doc - the doc
: @return - the root as a node
:)
declare function model:get-root-node(
    $domain-model as element(domain:model),
    $doc as node()) 
as node() {
   if($doc instance of document-node()) then $doc/* else $doc
};

(:~
: This function checks the parameters for an identifier that signifies the instance of a model
: @param - $domain-model - domain model of the content
: @param - $params - parameters of content that pertain to the domain model
: @return a identity or uuid value (repsective) for identifying the model instance
:)
declare function model:get-id-from-params(
   $domain-model as element(domain:model), 
   $params as map:map)  
as xs:string+
{
   let $id-field := domain:get-model-identity-field-name($domain-model)
   let $id-key := 
     $domain-model/(domain:element|domain:attribute)[@name eq $id-field]
   return
      (domain:get-field-id($id-key),fn:data($id-key/@name))
};

(:~
 : Gets only the params for a given model
 : @param - $domain-model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @param - $strict - boolean value on whether to be strict or not
 :)
declare function model:get-model-params(
   $domain-model as element(domain:model),
   $params as map:map,
   $strict as xs:boolean
   )
{
   let $model-params := map:map()
   return (
     for $f in $domain-model/(domain:element|attribute)
     return (
        map:put($model-params,$f/@name,map:get($params,$f/@name)),
        map:delete($model-params,$f/@name)
     ),  
     if(map:count($params) gt 0 and $strict) 
     then fn:error(xs:QName("INVALID-PARAMETERS"),"Additional Parameters are not allowed in strict mode")
     else (),     
        $model-params
   )
};

(:~
 :  Creates a new instance of an asset and returns that instance but does not persist in database
 :)
declare function model:new(
  $domain-model as element(domain:model)
){
   model:recursive-create($domain-model,map:map())
};

(:~
 :  Creates a new instance of a model but does not persisted.
 :)
declare function model:new(
  $domain-model as element(domain:model),
  $params as map:map
){
     model:recursive-create($domain-model,$params)
};

(:~
 : Creates any binary nodes associated with model instance
 :)
declare function model:create-binary-dependencies(
  $identity as xs:string,
  $instance as element()
) {
     model:create-binary-dependencies($identity,$instance,xdmp:default-permissions(),xdmp:default-collections())
};

(:~
 :  Inserts any binary dependencies created from binary|file type elements
 :)
declare function model:create-binary-dependencies(
  $identity as xs:string,
  $instance as element(),
  $permissions as element(sec:permission)*,
  $collections as xs:string*
) {
        xdmp:log(fn:concat("Creating Binary::",map:count($binary-dependencies)),"debug"),
        for $k in map:keys($binary-dependencies)
        return (
            xdmp:document-insert(
                      $k,
                      map:get($binary-dependencies,$k),
                      xdmp:default-permissions(),
                      $identity
            ), (:~Cleanup map :)
            map:delete($binary-dependencies,$k)
            )
};

(:~ 
 : Creates a model for a given domain
 : @param - $domain-model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @returns element
 :) 
declare function model:create(
    $domain-model as element(domain:model), 
    $params as map:map
) 
as element()?
{
    model:create($domain-model, $params, xdmp:default-collections(),xdmp:default-permissions())
};

(:~ 
 : Creates a model for a given domain
 : @param - $domain-model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @returns element
 :) 
declare function model:create(
    $domain-model as element(domain:model), 
    $params as map:map,
    $collections as xs:string*,
    $permissions as element(sec:permission)*
) 
as element()?
{

  let $id := model:get-id-from-params($domain-model,$params)
  let $current := model:get($domain-model,$params)
  return
      (: Check if the document exists  first before trying to create it :)
      if ($current) then 
          fn:error(xs:QName("DOCUMENT-EXISTS"),fn:concat("The document already exists. ID : %1 at %2"),
            ($current/*[fn:local-name(.) = $id],
              xdmp:node-uri($current))
             )
      else   
        let $identity := model:generate-uuid()
        (: Validate the parameters before trying to build the document :)
        let $validation :=  model:validate-params($domain-model,$params,"create") 
        return
         if(fn:count($validation) > 0) 
         then fn:error(xs:QName("VALIDATION-ERROR"), fn:concat("The document trying to be created contains validation errors"), $validation)    
         else 
           let $name := $domain-model/@name
           let $persistence := $domain-model/@persistence
           let $update := model:recursive-create($domain-model,$params)
           let $computed-collections := 
                model:build-collections(($domain-model/domain:collection,map:get($params,"_collection")),$domain-model,$update)        
           return (
               (: Return the update node :)
               $update,
               (: Creation for document persistence :)
               if ($persistence = 'document') then
                   let $path := $domain-model/domain:document/text() 
                   let $field-id := domain:get-field-value(domain:get-model-identity-field($domain-model),$update)
                   let $doc := fn:doc($path)
                   let $root-node := fn:data($domain-model/domain:document/@root)
                   let $root-namespace := domain:get-field-namespace($domain-model)
                   return (
                       if ($doc) then
                         let $root :=  model:get-root-node($domain-model,$doc)
                         return 
                           if($root) then 
                              (: create the instance of the model in the document :)      
                               xdmp:node-insert-child($root,$update)
                           else fn:error(xs:QName("ROOT-MISSING"),"Missing Root Node",$doc) 
                       else (
                           xdmp:document-insert(
                             $path,
                             element { fn:QName($root-namespace,$root-node) } { $update },
                             $permissions,
                             fn:distinct-values(($computed-collections,$collections))
                          )
                      ),
                      model:create-binary-dependencies($identity,$update)
                  )
               (: Creation for directory persistence :)
               else if ($persistence = 'directory') then
                    let $field-id := domain:get-field-value(domain:get-model-identity-field($domain-model),$update)
                    let $computed-collections := 
                          model:build-collections(($domain-model/domain:collection,map:get($params,"_collection")),$domain-model,$update)        
                    let $path := 
                        fn:concat(
                            model:build-uri($domain-model/domain:directory/text(),$domain-model,$update) , 
                            $field-id
                        , ".xml")
                    return (
                        xdmp:document-insert(
                             $path,
                             $update,
                             $permissions,
                             fn:distinct-values(($computed-collections,$collections))
                        ),
                        model:create-binary-dependencies($identity,$update)
                    )
              (:Singleton Persistence is good for configuration Files :)
               else if($persistence = 'singleton') then 
                   let $field-id := domain:get-field-value($domain-model/(domain:element|domain:attribute)[@type eq "identity"],$update)
                   let $path := $domain-model/domain:document/text() 
                   let $doc := fn:doc($path)
                   let $root-namespace := domain:get-field-namespace($domain-model)
                    let $computed-collections := 
                          model:build-collections(($domain-model/domain:collection,map:get($params,"_collection")),$domain-model,$update)        
                   return (
                       if ($doc) then
                            (: create the instance of the model in the document :)      
                            xdmp:node-replace(model:get-root-node($domain-model,$doc),$update)
                       else
                           xdmp:document-insert(
                             $path,
                             element { fn:QName($root-namespace,$domain-model/@name) } { $update },
                             $permissions,
                            fn:distinct-values(($computed-collections,$collections))
                          ),
                       model:create-binary-dependencies($field-id,$update)
                   )
               else fn:error(xs:QName("ERROR"),"No document persistence defined for creation.")
           )
};

(:~
 : Returns if the passed in _query param will return a model exists
 :)
declare function model:exists(  
  $domain-model as element(domain:model),
  $params as map:map
) {
   let $namespace := domain:get-field-namespace($domain-model)
   let $localname   := fn:data($domain-model/@name)
   return   
       xdmp:exists(
         cts:search(fn:doc(),
           cts:element-query(fn:QName($namespace,$localname),
                cts:and-query(( 
                      if($domain-model/@persistence = "directory")
                      then cts:directory-query($domain-model/domain:directory,"1")
                      else if($domain-model/@persistence ="document") 
                      then cts:document-query($domain-model/domain:document)
                      else (),
                      map:get($params,"_query")                  
                ))
           )
       )) 
};
(:~
: Retrieves a model document by id
: @param $domain-model the model of the document
: @param $params the values to pull the id from
: @return the document
 :) 
declare function model:get(
   $domain-model as element(domain:model), 
   $params as map:map
) as element()? {    
    (: Get document identifier from parameters :)
    (: Retrieve document identity and namspace to help build query :)
    let $id-field   := domain:get-model-identity-field-name($domain-model)
    let $id-field-def := $domain-model/(domain:attribute|domain:element)[@name = $id-field][1]
    let $id-fields  := model:get-id-from-params($domain-model,$params)
    let $id-value   := fn:data((for $k in $id-fields return map:get($params, $k))[1])
    let $name := fn:data($domain-model/@name)
    let $nameSpace := domain:get-field-namespace($domain-model)
    let $idns := domain:get-field-namespace($id-field-def)
    let $stmt := 
      fn:normalize-space(fn:string(
      <stmt>cts:search({
                (: Build a query to search within the give document :)
                if ($domain-model/@persistence = 'document') then
                    let $rootNode := fn:data($domain-model/domain:document/@root)
                    (: if namespaces are given use it :)
                    let $xpath := 
                        if($nameSpace) then
                           fn:concat("/*:", $rootNode, "[fn:namespace-uri(.) = '", $nameSpace, "']/*:", $name, "[fn:namespace-uri(.) = '", $nameSpace, "']")
                        else 
                            fn:concat("/", $rootNode, "/", $name)
                    return
                        (: Create a constraint :)
                        fn:concat('fn:doc("', $domain-model/domain:document/text() , '")', $xpath )
                else 
                    (: otherwise for document persistance search against the proper root node :)
                    fn:concat("/*:",$name, "[fn:namespace-uri(.) = '", $nameSpace, "']") 
            },
            cts:or-query((
               if($id-field-def instance of element(domain:element))
               then cts:element-range-query(fn:QName("{$idns}","{$id-field}"),"=","{$id-value}")
               else if($id-field-def instance of element(domain:attribute))
                    then cts:element-attribute-range-query(fn:QName("{$idns}","{$name}"),fn:QName("","{$id-field}"),"=","{$id-value}")
                    else ()
            )), ("filtered"))
        </stmt>))
    return (
        (: Execute statement :)
        xdmp:log(("model:get::",$stmt)),
        xdmp:value($stmt)
        )
};
(:~
: Retrieves a model document by id
: @param $domain-model the model of the document
: @param $params the values to pull the id from
: @return the document
 :) 
declare function model:getByReferenceKeyLabel(
   $domain-model as element(domain:model), 
   $params as map:map
) as element()? {    
    (: Get document identifier from parameters :)
    (: Retrieve document identity and namspace to help build query :)
    let $name := fn:data($domain-model/@name)
    let $id-field   := domain:get-model-identity-field-name($domain-model)
    let $key-field := fn:data($domain-model/@keyLabel)
    let $key-field-def := $domain-model//(domain:element|domain:attribute)[@name eq $key-field]
    let $model-name := fn:data($key-field-def/ancestor::domain:model/@name)
    let $key-value := domain:get-field-id($key-field-def)
    let $nameSpace := domain:get-field-namespace($domain-model)
    let $value := (map:get($params,$key-field),map:get($params,$key-value),map:get($params,$id-field))[1]
    let $stmt := 
      fn:normalize-space(fn:string(
      <stmt>cts:search({
                    (: Build a query to search within the give document :)
                    if ($domain-model/@persistence = 'document') then
                        let $rootNode := fn:data($domain-model/domain:document/@root)
                        (: if namespaces are given use it :)
                        let $xpath := 
                            if($nameSpace) then
                               fn:concat("/*:", $rootNode, "[fn:namespace-uri(.) = '", $nameSpace, "']/*:", $name, "[fn:namespace-uri(.) = '", $nameSpace, "']")
                            else 
                                fn:concat("/", $rootNode, "/", $name)
                        return
                            (: Create a constraint :)
                            fn:concat('fn:doc("', $domain-model/domain:document/text() , '")', $xpath )
                    else 
                        (: otherwise for document persistance search against the proper root node :)
                        fn:concat("/*:",$name, "[fn:namespace-uri(.) = '", $nameSpace, "']") 
                },
                cts:or-query((
                    if($domain-model/@persistence = "document") then
                        if($key-field-def instance of element(domain:attribute)) 
                        then cts:element-attribute-value-query(fn:QName("{$nameSpace}","{$model-name}"),fn:QName("","{$id-field}"),"{$value}","exact")
                        else cts:element-value-query(fn:QName("{$nameSpace}","{$key-field}"),"{$value}")
                    else                     
                    if($key-field-def instance of element(domain:attribute)) 
                    then cts:element-attribute-range-query(fn:QName("{$nameSpace}","{$model-name}"),fn:QName("","{$id-field}"),"=","{$value}","exact")
                    else cts:element-range-query(fn:QName("{$nameSpace}","{$key-field}"),"=","{$value}")
                )), ("filtered"))
        </stmt>))
    let $exprValue := xdmp:value($stmt)
    return (
        (: Execute statement :)
        xdmp:log(("model:getByReference::",$exprValue),"debug"),
        $exprValue      
        )
};
declare function model:update-partial(
    $domain-model as element(domain:model),
    $params as map:map
) {
    model:update-partial($domain-model,$params,())
};
(:~
 : Creates an partial update statement for a given model.
 :)
declare function model:update-partial(
    $domain-model as element(domain:model), 
    $params as map:map,
    $collections as xs:string*
){
   let $current := model:get($domain-model,$params)
   let $id := $domain-model//(domain:container|domain:element|domain:attribute)[@identity eq "true"]/@name
   let $identity-field := $domain-model//(domain:element|domain:attribute)[@identity eq "true" or @type eq "identity"]
   let $identity := domain:get-field-value($identity-field,$current)
   return 
     if($current) then
        let $build := model:recursive-build($domain-model,$current,$params,fn:true())
        let $validation := model:validate-params($domain-model,$params,"update")
        let $computed-collections := model:build-collections(($domain-model/domain:collection,map:get($params,"_collection")),$domain-model,$build)
        return
            if(fn:count($validation) > 0) then
                fn:error(xs:QName("VALIDATION-ERROR"), fn:concat("The document trying to be updated contains validation errors"), $validation)    
            else (
                xdmp:document-insert(
                    xdmp:node-uri($current),
                    $build,
                    xdmp:document-get-permissions(xdmp:node-uri($current)),
                    fn:distinct-values(($collections,$computed-collections,xdmp:document-get-collections(xdmp:node-uri($current))))
                ),
                model:create-binary-dependencies($identity,$current)
            )
     else 
       fn:error(xs:QName("ERROR"), "Trying to update a document that does not exist.")
};

(:~
 : Overloaded method to support existing controller functions for adding collections
 :)
declare function model:update($domain-model as element(domain:model),$params as map:map) {
   model:update($domain-model,$params,xdmp:default-collections())
};

(:~
 : Overloaded method to support existing controller functions for adding collections and partial update
 :)
declare function model:update(
    $domain-model as element(domain:model),
    $params as map:map,
    $collections as xs:string*) {
   model:update($domain-model,$params,$collections,fn:false())
};


(:~
 : Creates an update statement for a given model.
 : @param $domain-model - domain element for the given update
 : @param $params - List of update parameters for a given update, the uuid element must be present in the document
 : @param $collections - Additional collections to add to document
 : @param $partial - if the update should pull the values of the current-node if no params key is present
 :)
declare function model:update(
    $domain-model as element(domain:model), 
    $params as map:map,
    $collections as xs:string*,
    $partial as xs:boolean)
{
   let $params := domain:fire-before-event($domain-model,"update",$params) 
   let $current := model:get($domain-model,$params)
   let $id := $domain-model//(domain:container|domain:element|domain:attribute)[@identity eq "true"]/@name
   let $identity-field := $domain-model//(domain:element|domain:attribute)[@identity eq "true" or @type eq "identity"]
   let $identity := (domain:get-field-value($identity-field,$current))[1]
   let $persistence := fn:data($domain-model/@persistence)
   return 
     if($current) then
        let $build := model:recursive-update($domain-model,$current,$params,$partial)
        let $validation := model:validate-params($domain-model,$params,"update")
        let $computed-collections := model:build-collections(($domain-model/domain:collection,map:get($params,"_collection")),$domain-model,$build)
        return
            if(fn:count($validation) > 0) then
                fn:error(xs:QName("VALIDATION-ERROR"), fn:concat("The document trying to be updated contains validation errors"), $validation)    
            else (
               if($persistence = "document") then 
                  xdmp:node-replace($current,$build)
               else if($persistence = "directory") then 
                  xdmp:document-insert(
                    xdmp:node-uri($current),
                    $build,
                    xdmp:document-get-permissions(xdmp:node-uri($current)),
                    fn:distinct-values(($collections,$computed-collections,xdmp:document-get-collections(xdmp:node-uri($current))))
                )
             else fn:error(xs:QName("UPDATE-NOT-PERSISTABLE"),"Cannot Update Model with persistence: " || $persistence,$persistence),
                model:create-binary-dependencies($identity,$current),
                domain:fire-after-event($domain-model,"update",$build)
            )
            (:Create delta map and save and logged:)
     else 
       fn:error(xs:QName("UPDATE-NOT-EXISTS"), "Trying to update a document that does not exist.")
};
declare function model:create-or-update($domain-model as element(domain:model),$params as map:map) {
   if(model:get($domain-model,$params)) then model:update($domain-model,$params)
   else model:create($domain-model,$params)
   };
(:~
 :  Returns all namespaces from domain:model and inherited from domain
 :)
declare function model:get-namespaces($model as element(domain:model)) {
   let $ns-map := map:map()
   let $nses := 
      for $kv in (
        fn:root($model)/(domain:content-namespace|domain:declare-namespace),
        $model/domain:declare-namespace
     )
      return map:put($ns-map, ($kv/@prefix),fn:data($kv/@namespace-uri))
   for $ns in map:keys($ns-map)
   return 
     <ns prefix="{$ns}" namespace-uri="{map:get($ns-map,$ns)}"/>
};

(:~
 :  Function allows for partial updates 
 :)
declare function model:recursive-update-partial(
$context as element(),
$current as node()?,
$updates as map:map)
{
  let $current := ()
  return $current
};

(:~
 :  Entry for recursive updates
 :)
declare function model:recursive-create(
   $context as node(),
   $updates as map:map
){
    model:recursive-build($context, (), $updates) 
};


(:~
 :  
 :)
declare function model:recursive-update(   
   $context as node(),
   $current as node(),
   $updates as map:map,
   $partial as xs:boolean
) 
{
    model:recursive-build( $context, $current, $updates,$partial) 
};


(:~
 :  
 :)
declare function model:recursive-update(   
   $context as node(),
   $current as node(),
   $updates as map:map
) 
{
    model:recursive-build( $context, $current, $updates) 
};

declare function model:recursive-build(
   $context as node(),
   $current as node()?,
   $updates as map:map
) {
   model:recursive-build($context,$current,$updates,fn:false())
};

(:~
 :  Recurses the field structure and builds up a document
 :)
declare function model:recursive-build(
   $context as node(),
   $current as node()?,
   $updates as map:map,
   $partial as xs:boolean
) {
   let $type := fn:data($context/@type)
   let $key  := domain:get-field-id($context)
   let $current-value := domain:get-field-value($context,$key,$current)
   let $default-value := fn:data($context/@default)
   return    
   typeswitch($context)
   (: Build out any domain Models :)
   case element(domain:model) return
        let $attributes := 
            for $a in $context/domain:attribute 
            return 
               model:recursive-build($a, $current,$updates)
        let $ns := domain:get-field-namespace($context)
        let $nses := model:get-namespaces($context)
        let $localname := fn:data($context/@name)
        let $default   := fn:data($context/@default)
        return 
            element {(fn:QName($ns,$localname))} {
                for $nsi in $nses
                return 
                  namespace {$nsi/@prefix}{$nsi/@namespace-uri},
                $attributes,
                for $n in $context/(domain:element|domain:container)
                return 
                    model:recursive-build($n,$current,$updates,$partial)             
            }
     (: Build out any domain Elements :)     
     case element(domain:element) return
        let $attributes := 
            for $a in $context/domain:attribute 
            return 
                model:recursive-build($a,$current, $updates,$partial)        
        let $ns := domain:get-field-namespace($context)
        let $localname := fn:data($context/@name)
        let $default   := (fn:data($context/@default),"")[1]
        let $occurrence := ($context/@occurrence,"?")
        let $map-values := domain:get-field-param-value($context, $updates)
        return 
             if ($context/@type eq "reference" and $context/@reference ne "") then 
                 if($map-values) then              
                    model:build-value($context, $map-values, $current-value)
                 else if($partial and $current) then
                    $current-value   
                 else ()
             else if ($type  = ("binary","file") and $map-values) then 
                let $model := $context/ancestor::domain:model
                let $field-id := domain:get-field-id($context)
                let $fileType := ($context/@fileType,"auto")[1]
                let $binary := map:get($updates,$field-id)
                let $binary := if($binary) then $binary else map:get($updates,fn:data($context/@name))
                let $log := xdmp:log(fn:concat("BinaryFound::",fn:exists($binary)))
                let $binaryFile := 
                  if(fn:exists($binary)) then 
                      if($fileType eq "xml") then
                          if ($binary instance of binary ()) then
                              xdmp:unquote(xdmp:binary-decode($binary,"utf-8"))
                          else
                              xdmp:unquote($binary/node()) 
                      else if($fileType eq "text") then
                          xdmp:binary-decode($binary,"utf-8")
                      else $binary
                  else ()                    
                let $fileURI := $context/@fileURI
                let $fileURI := 
                   if($fileURI and $fileURI ne "")               
                   then model:build-uri($fileURI,$model,$updates) 
                   else 
                      let $binDirectory := $model/domain:binaryDirectory
                      let $hasBinDirectory := 
                           if($binDirectory or $fileURI) then () 
                           else fn:error(xs:QName("MODEL-MISSING-BINARY-DIRECTORY"),"Model must configure field/@fileURI or model/binaryDirectory if binary/file fields are present",$field-id)
                      return 
                           model:build-uri($binDirectory,$model,$updates) 
                let $filename := 
                     if(map:get($updates,fn:concat($field-id,"_filename")))
                     then map:get($updates,fn:concat($field-id,"_filename"))
                     else map:get($updates,fn:concat($context/@name,"_filename"))
                let $fileContentType := 
                     if(map:get($updates,fn:concat($field-id,"_content-type")))
                     then map:get($updates,fn:concat($field-id,"_content-type"))
                     else map:get($updates,fn:concat($context/@name,"_content-type"))
                return 
                     if(fn:exists($binary)) then (
                         element {fn:QName($ns,$localname)} {
                            attribute type {"binary"},
                            attribute content-type {$fileContentType}, 
                            attribute filename {$filename},
                            attribute filesize {
                             if($binaryFile instance of binary())
                             then xdmp:binary-size($binaryFile)
                             else fn:string-length(xdmp:quote($binaryFile))      
                            },
                            text {$fileURI}
                         },
                         if($fileURI ne $current/text()) 
                         then  xdmp:document-delete($current/text())
                         else  (),
                        (:Binary Dependencies will get replaced automatically:)             
                         map:put($binary-dependencies,$fileURI,$binaryFile)                        
                     ) 
                     else 
                         $current-value

             else  if ($type = "schema-element") then
                if(fn:exists($map-values)) then (
                  element {(fn:QName($ns,$localname))}{
                     model:build-value($context, $map-values, $current-value)
                 })
                else if($partial and $current-value) then 
                   $current-value
                else                     
                    $default-value
            else
                if(fn:exists($map-values)) then 
                   for $value in $map-values
                   return
                      element {(fn:QName($ns,$localname))}{
                         $attributes,
                         model:build-value($context,  $value, $current-value)
                       }
                else if($partial and $current-value) then 
                      $current-value
                else element {(fn:QName($ns,$localname))}{
                         $attributes,
                         model:build-value($context, $map-values, $current-value)
                       }
                       
     (: Build out any domain Attributes :)              
     case element(domain:attribute) return
        let $ns := ($context/@namespace-uri,$context/@namespace)[1] (:Attributes are only in namespace if they are declared:)
        let $localname := fn:data($context/@name)
        let $default   := (fn:data($context/@default),"")[1]
        let $occurrence := ($context/@occurrence,"?")
        let $map-value := domain:get-field-param-value($context, $updates)
        let $value := $map-value
        return 
          if($value) then 
          attribute {(fn:QName($ns,$localname))}{
            model:build-value($context, $value,$current-value)
          } else if($partial and $current) then 
            $current-value
          else if(fn:exists(model:build-value($context, $value,$current-value))) then
          attribute {(fn:QName($ns,$localname))}{
            model:build-value($context, $value,$current-value)
          } 
          else if($default) then attribute {(fn:QName($ns,$localname))}{
            $default
          } else ()
          
     (: Build out any domain Containers :)     
     case element(domain:container) return
        let $ns := domain:get-field-namespace($context)
        let $localname := fn:data($context/@name)
        return 
          element {(fn:QName($ns,$localname))}{
           for $n in $context/(domain:attribute|domain:element|domain:container)
           return 
             model:recursive-build($n, $current ,$updates,$partial)
           }
           
     (: Return nothing if the type is not of Model, Element, Attribute or Container :)      
     default return ()
};

(:~
: Deletes the model document
: @param $domain-model the model of the document and any external binary files
: @param $params the values to fill into the element
: @return xs:boolean denoted whether delete occurred
:)  
declare function model:delete($domain-model as element(domain:model),$params as map:map)
as xs:boolean
{
  let $current := model:get($domain-model,$params)
  let $is-referenced := domain:is-model-referenced($domain-model,$current)
  let $is-current := if($current) then () else fn:error(xs:QName("DELETE-ERROR"),"Could not find a matching document")
  return
    try {
      if($is-referenced) then 
        fn:error(
            xs:QName("REFERENCE-CONSTRAINT-ERROR"),
           "You are attempting to delete document which is referenced by other documents",
           domain:get-model-reference-uris($domain-model,$current)
        )
      else 
       ( xdmp:node-delete($current)
        ,model:delete-binary-dependencies($domain-model,$current)
        ,fn:true() )
    } catch($ex) {
       xdmp:rethrow()  
    }
};

(:~
 : Deletes any binaries defined by instance
 :)
declare function model:delete-binary-dependencies(
    $domain-model as element(domain:model),
    $current as element()
) {
   let $binary-fields := $domain-model//domain:element[@type = ("binary","file")]
   for $field in $binary-fields
   let $value := domain:get-field-value($field,$current)
   return
      if(fn:normalize-space($value) ne "" and fn:not(fn:empty($value)))
      then 
      if(fn:doc-available($value)) then
        xdmp:document-delete($value)
      else (
         xdmp:log(fn:concat("DELETE-FILE-MISSING::field=",$field/@name," value=",$value),"log")
      )
      else ()(:Binary not set so dont do anything:)
};
 
(:~
 :  Returns the lookup 
 :)
declare function model:lookup($domain-model as element(domain:model), $params as map:map) 
{
    let $key := fn:data($domain-model/@key)
    let $label := fn:data($domain-model/@keyLabel)
    let $name := fn:data($domain-model/@name)
    let $nameSpace :=  domain:get-field-namespace($domain-model)
    let $qString := map:get($params,"q")
    let $limit := 
        if(map:get($params,"ps")) 
        then (map:get($params,"ps"),'10')[1] cast as xs:integer
        else ()
    let $keyField := domain:get-model-key-field($domain-model) (:$domain-model//(domain:attribute|domain:element)[@name = $key]:)
    let $keyLabel := domain:get-model-keyLabel-field($domain-model)(:$domain-model//(domain:attribute|domain:element)[@name = $label]:)
    let $debug := map:get($params,"debug")
    let $additional-constraint := map:get($params,"_query")
    let $query := cts:and-query((
                 cts:element-query(fn:QName($nameSpace,$name),
                    if($qString ne "") 
                    then cts:word-query(fn:concat("*",$qString,"*"),("diacritic-insensitive", "wildcarded","case-insensitive","punctuation-insensitive"))
                    else cts:and-query(())
                 ),
                 if($domain-model/@persistence = "directory")
                 then cts:directory-query($domain-model/domain:directory)
                 else cts:document-query($domain-model/domain:document)
                 ,$additional-constraint
              ))
    let $values := 
        if($domain-model/@persistence = 'document') then
            let $loc :=  $domain-model/domain:document
            let $rootNode :=fn:data($loc/@root)
            let $xpath := 
                if($nameSpace) then
                    fn:concat("/*:", $rootNode, "[fn:namespace-uri(.) = '", $nameSpace, "']/*:", $name, "[fn:namespace-uri(.) = '", $nameSpace, "']")
                else 
                    fn:concat("/", $rootNode, "/", $name)
            
            let $stmt :=  fn:string(<stmt>{fn:concat('fn:doc("', $loc/text() , '")', $xpath)}</stmt>)
            let $nodes := xdmp:value($stmt)
            let $lookup-values := 
              for $node in $nodes[cts:contains(.,$query)]
               let $key   := $node/(@*|*)[fn:local-name(.) = $key]/text()
               let $value := $node/(@*|*)[fn:local-name(.) = $label]/text()
               order by $value,$key
              return 
                  <lookup>
                      <key>{$key}</key>
                      <label>{$value}</label>
                  </lookup>
            return 
              if($limit) 
              then $lookup-values[1 to $limit]
              else $lookup-values
        else if ($domain-model/@persistence = 'directory') then
                let $keyFieldRef := 
                    if($keyField instance of element(domain:attribute))
                    then cts:element-attribute-reference(fn:QName($nameSpace,$domain-model/@name),fn:QName("",$keyField/@name))
                    else cts:element-reference(fn:QName($nameSpace,$keyField/@name))  
                let $keyLabelRef := 
                    if($keyLabel instance of element(domain:attribute))
                    then cts:element-attribute-reference(fn:QName($nameSpace,$domain-model/@name),fn:QName("",$keyLabel/@name))
                    else cts:element-reference(fn:QName($nameSpace,$keyLabel/@name))                  
                for $item in 
                    cts:value-co-occurrences(
                        $keyLabelRef,
                        $keyFieldRef,
                        ("item-order",if($limit) then fn:concat('limit=',$limit) else ()),
                        $query)
                return 
                  <lookup>
                      <key>{fn:data($item/cts:value[2])}</key>
                      <label>{fn:data($item/cts:value[1])}</label>
                  </lookup>
        else ()
    return
        <lookups type="{$domain-model/@name}">
        {if($debug) then $query else ()}
        {$values}
       </lookups>
};

(:~Recursively Removes elements based on @listable = true :)
declare function model:filter-list-result($field as element(),$result) {
      if($field/domain:navigation/@listable = "false") 
      then ()
      else 
        if($field/(domain:element|domain:container|domain:attribute))
        then 
          typeswitch($field)
            case element(domain:model) return    
                element {fn:QName(domain:get-field-namespace($field),$field/@name)} {
                   for $field in $field/(domain:element|domain:attribute|domain:container)
                   return 
                     model:filter-list-result($field,$result)
                }
            case element(domain:element) return 
                element {fn:QName(domain:get-field-namespace,$field/@name)} {
                   for $field in $field/(domain:element|domain:attribute|domain:container)
                   return model:filter-list-result($field,$result)
                }
            case element(domain:container) return 
                  element {fn:QName(domain:get-field-namespace($field),$field/@name)} {
                     for $field in $field/(domain:element|domain:attribute|domain:container)                  
                     return model:filter-list-result($field,$result)
                  }
            case element(domain:attribute) return 
                attribute {fn:QName("",$field/@name)} {
                  domain:get-field-value($field,$result)
                } 
            default return ()                
        else domain:get-field-value($field,$result)   
};
(:~
: Returns a list of packageType
: @return  element(packageType)*   
:)    
declare function model:list($domain-model as element(domain:model), $params as map:map) 
as element(list)? 
{
    let $listable := fn:not($domain-model/domain:navigation/@listable eq "false")
    return
    if(fn:not($listable))
    then fn:error(xs:QName("MODEL-NOT-LISTABLE"),fn:concat($domain-model/@name, " is not listable"))
    else 
        let $search := model:list-params($domain-model,$params)
        let $persistence := $domain-model/@persistence
        let $name := $domain-model/@name
        let $namespace := domain:get-field-namespace($domain-model)
        let $predicateExpr := ()
        let $additional-query:= map:get($params,"_query")
        let $list  := 
            if ($persistence = 'document') then
                let $path := $domain-model/domain:document/text()
                let $root := fn:data($domain-model/domain:document/@root)                
                return
                  xdmp:value("fn:doc($path)/*:" || $root || "/*:"  || $name ||  "[cts:contains(.,cts:and-query(($search,$additional-query)))]")
                  (:fn:doc($path)/*/*[cts:contains(.,cts:and-query(($search,$additional-query)))]:)
            else 
                let $dir := cts:directory-query($domain-model/domain:directory/text())
                let $predicate := 
                    cts:element-query(fn:QName($namespace,$name),
                        cts:and-query((
                            $additional-query,
                            $search,
                            $dir
                            )
                    ))
                let $_ := xdmp:set($predicateExpr,$predicate)
                return
                    cts:search(fn:collection(),$predicate)      
        let $total :=
            if($persistence = 'document') 
            then fn:count($list)
            else xdmp:estimate(cts:search(fn:collection(),cts:element-query(fn:QName($namespace,$name),cts:and-query(($search,$predicateExpr))))) 
        let $sort := 
            let $sort-field        := map:get($params,"sidx")[1][. ne ""]
            let $sort-order        := map:get($params,"sord")[1]
            let $model-sort-field  := $domain-model/domain:navigation/@sortField/fn:data(.)
            let $model-order       := ($domain-model/domain:navigation/@sortOrder/fn:data(.),"ascending")[1]
            let $domain-sort-field := $domain-model//(domain:element|domain:attribute)[@name = ($sort-field,$model-sort-field)][1]
            let $domain-sort-as := 
              if($domain-sort-field) 
              then fn:concat("[1] cast as ", domain:resolve-datatype($domain-sort-field))
              else ()
            let $domain-sort-order := 
                if($sort-order) then $sort-order
                else if($model-order) then $model-order
                else ()
            return 
            if($domain-sort-field) then 
                if($sort-order = ("desc","descending"))
                then fn:concat("($__context__//*:",$domain-sort-field/@name,")",$domain-sort-as,"? descending")
                else fn:concat("($__context__//*:",$domain-sort-field/@name,")",$domain-sort-as,"? ascending")
            else if($model-sort-field and $model-sort-field ne "") then 
                (if($model-order = ("desc","descending"))
                then fn:concat("($__context__//*:",$model-sort-field,")"," descending")
                else fn:concat("($__context__//*:",$model-sort-field,")"," ascending")
                )
            else ()            
        let $page     := xs:integer((map:get($params, 'page'),1)[1])    
        let $pageSize := xs:integer((map:get($params,'rows'),50)[1])
        let $start    := ($page - 1) * $pageSize + 1
        let $last     :=  $start + $pageSize - 1
        let $end      := if ($total > $last) then $last else $total
        let $resultsExpr := 
            if($sort ne "" and fn:exists($sort)) 
            then fn:concat("(for $__context__ in $list order by ",$sort, " return $__context__)[",$start, " to ",$end,"]")              
            else "($list)[$start to $end]" 
        let $results :=  xdmp:value($resultsExpr)            
        let $results := 
            if($persistence = "directory") 
            then 
                for $result in $results
                return  
                 model:filter-list-result($domain-model,$result/node())
            else  $results                 
        return 
           <list type="{$name}" elapsed="{xdmp:elapsed-time()}">
             <currentpage>{$page}</currentpage>
             <pagesize>{$pageSize}</pagesize>
             <totalpages>{fn:ceiling($total div $pageSize)}</totalpages>
             <totalrecords>{$total}</totalrecords>
             {(:Add Additional Debug Arguments:)
               if(map:get($params,"debug") = "true") then (
                 <debugQuery>{xdmp:describe($predicateExpr,(),())}</debugQuery>,
                 <searchString>{$search}</searchString>,
                 <sortString>{$sort}</sortString>,
                 <expr>{$resultsExpr}</expr>
              ) else ()
             }
             {$results}
           </list>
}; 

(:~
 : Converts Search Parameters to cts search construct for list;
 :)
declare function model:list-params(
    $domain-model as element(domain:model), 
    $params as map:map    
) {
      let $sf := map:get($params,"searchField"),
          $so := map:get($params,"searchOper"),
          $sv := map:get($params,"searchString"),
          $filters := map:get($params,"filters")[1]
      return
        if(fn:exists($sf) and fn:exists($so) and fn:exists($sv) and
           $sf ne "" and $so ne "")
        then           
            let $op := $so
            let $field-elem := $domain-model//(domain:element|domain:attribute)[@name eq $sf]
            let $field := fn:QName(domain:get-field-namespace($field-elem),$field-elem/@name)
            let $value := map:get($params,"searchString")[1]
            return
                operator-to-cts($field-elem,$op,$value)                
       else if(fn:exists($filters[. ne ""])) then
            let $parsed  := <x>{xdmp:from-json($filters)}</x>/*
            let $_ := xdmp:log($parsed)
            let $groupOp := ($parsed/json:entry[@key eq "groupOp"]/json:value,"AND")[1]
            let $rules := 
                for $rule in $parsed//json:entry[@key eq "rules"]/json:value/json:array/json:value/json:object
    
                let $op :=  $rule/json:entry[@key='op']/json:value
                let $sf :=  $rule/json:entry[@key='field']/json:value
                let $sv :=  $rule/json:entry[@key='data']/json:value
                let $field-elem := $domain-model//(domain:element|domain:attribute)[@name eq $sf]
                let $field := 
                    fn:QName(domain:get-field-namespace($field-elem),$field-elem/@name)
                return
                  if($op and $sf and $sv) then
                  operator-to-cts($field-elem,$op, $sv)
                  else ()
            let $log := xdmp:log(("rules::", $rules),"debug")
            return
               if($groupOp eq "OR") then
                   cts:or-query((
                      $rules
                   ))
               else cts:and-query((
                 $rules
               ))
            else  ()                   
};

(:~
 : Converts a list operator to its cts:* equivalent
 :)
declare private function model:operator-to-cts(
    $field as element(),
    $op as xs:string,
    $value as item()?){
    model:operator-to-cts($field,$op,$value,fn:false())
};

(:~
 : Converts a list operator to its cts:equivalent
 :)
declare private function model:operator-to-cts(
    $field-elem as element(),
    $op as xs:string,
    $value as item()?,
    $ranged as xs:boolean
) {
  let $field := fn:QName(domain:get-field-namespace($field-elem),$field-elem/@name)
  return 
   if($field-elem/@type eq "reference") then
     let $ref := fn:QName("","ref-id")   
     return 
          if($op eq "eq") then
             if($ranged) 
             then cts:or-query((
                    cts:element-attribute-range-query($field,$ref,"=",$value),
                    cts:element-value-query($field,$value)
                  ))
             else cts:or-query((
                    cts:element-attribute-value-query($field,$ref,$value),
                    cts:element-value-query($field,$value)
                  ))
          else if($op eq "ne") then
             if($ranged) 
             then cts:and-query((
                    cts:element-attribute-range-query($field,$ref,"!=",$value),
                    cts:element-range-query($field,"!=", $value)
                  ))
             else 
                cts:and-query((
                    cts:not-query( cts:element-attribute-value-query($field,$ref,$value)),
                    cts:not-query(cts:element-value-query($field,$value))
                ))
          else if($op eq "bw") then
              cts:or-query((
                cts:element-attribute-word-query($field,$ref,fn:concat($value,"*"),("wildcarded")),
                cts:element-value-query($field,$value,fn:concat($value,"*"),("wildcarded"))
              ))
          else if($op eq "bn") then
             cts:and-query((
                cts:not-query( cts:element-attribute-value-query($field,$ref,fn:concat($value,"*")),("wildcarded")),
                cts:not-query(cts:element-value-query($field,$value,fn:concat($value,"*")),("wildcarded"))
             ))
          else if($op eq "ew") then
              cts:and-query((
                 cts:element-attribute-value-query($field,$ref,fn:concat("*",$value),("wildcarded")),
                 cts:element-value-query($field,$value,fn:concat("*",$value),("wildcarded"))
              ))
          else if($op eq "en") then
             cts:and-query((
               cts:not-query(cts:element-attribute-value-query($field,$ref,fn:concat("*",$value),("wildcarded"))),
               cts:not-query(cts:element-value-query($field,fn:concat($value,"*")),("wildcarded")) 
             ))
          else if($op eq "cn") then
              cts:or-query((
                cts:element-attribute-word-query($field,$ref,fn:concat("*",$value,"*"),("wildcarded")),
                cts:element-word-query($field,fn:concat("*",$value,"*"),("wildcarded","case-insensitive"))
              ))
          else if($op eq "nc") then
             cts:and-query((
                cts:not-query(cts:element-attribute-value-query($field,$ref,fn:concat("*",$value,"*"))),
                cts:not-query(cts:element-value-query($field,fn:concat("*",$value,"*")))
             ))
          else if($op eq "nu") then
              cts:or-query((
                cts:element-attribute-value-query($field,$ref,cts:and-query(())),
                cts:element-query($field,cts:and-query(()))
              ))
          else ()
    else 
          if($op eq "eq") then
             if($ranged) 
             then cts:element-range-query($field,"=",$value)
             else cts:element-value-query($field,$value,"case-insensitive")
           else if($op eq "ne") then
             if($ranged) 
             then cts:element-range-query($field,"!=",$value)
             else cts:not-query( cts:element-value-query($field,$value))
           else if($op eq "bw") then
              cts:element-value-query($field,fn:concat($value,"*"),("wildcarded"))
           else if($op eq "bn") then
              cts:not-query( cts:element-value-query($field,fn:concat($value,"*"),("wildcarded")))
           else if($op eq "ew") then
              cts:element-value-query($field,fn:concat("*",$value))
           else if($op eq "en") then
              cts:not-query( cts:element-value-query($field,fn:concat("*",$value),("wildcarded")))
           else if($op eq "cn") then
              cts:element-word-query($field,fn:concat("*",$value,"*"),("wildcarded"))
           else if($op eq "nc") then
              cts:not-query( cts:element-word-query($field,fn:concat("*",$value,"*"),("wildcarded")))
           else if($op eq "nu") then
              cts:element-query($field,cts:and-query(()))
           else if($op eq "nn") then
              cts:element-query($field,cts:or-query(()))         
           else if($op eq "in") then
              cts:element-value-query($field,$value)
           else if($op  eq "ni") then
              cts:not-query( cts:element-value-query($field,$value))
           else ()
};
declare function model:build-search-options(
  $domain-model as element(domain:model)
)  as element(search:options)
{
   model:build-search-options($domain-model,map:map())  
};

(:~
 : Build search options for a given domain model
 : @param $domain-model the model of the content type
 : @return search options for the given model
 :)
declare function model:build-search-options(
    $domain-model as element(domain:model),
    $params as map:map  
) as element(search:options)
{
    let $properties := $domain-model//(domain:element|domain:attribute)[domain:navigation/@searchable = ('true')]
    let $modelNamespace :=  domain:get-field-namespace($domain-model)
    let $baseOptions := $domain-model/search:options
    let $nav := $domain-model/domain:navigation
    let $constraints := 
            for $prop in $properties[domain:navigation/@searchable = "true"]
            let $prop-nav := $prop/domain:navigation
            let $type := (
                $prop/domain:navigation/@searchType,
                if($prop-nav/(@suggestable|@facetable) = "true") then "range" else  "value")[1]
            let $facet-options := 
                $prop/domain:navigation/search:facet-option
            let $ns := domain:get-field-namespace($prop)
            let $prop-nav := $prop/domain:navigation
            return
                <search:constraint name="{$prop/@name}" label="{$prop/@label}">{
                  element { fn:QName("http://marklogic.com/appservices/search",$type) } {
                        attribute collation {domain:get-field-collation($prop)},
                        if ($type eq 'range') 
                        then attribute type { domain:resolve-ctstype($prop) }
                        else attribute type {"xs:string"},
                        if ($prop-nav/@facetable eq 'true') 
                        then attribute facet { fn:true() }
                        else  attribute facet { fn:false() },
                        <search:element name="{$prop/@name}" ns="{$ns}" >{
                            (
                                if ($prop instance of attribute()) then
                                  <search:attribute name="{$prop/@name}" ns="{$ns}"/> 
                                else ()
                            )
                        }</search:element>,
                        $facet-options
                  }
                }</search:constraint>
      let $suggestOptions :=  
        for $prop in $properties[domain:navigation/@suggestable = "true"]
        let $type := ($prop/domain:navigation/@searchType,"value")[1]
        let $collation := domain:get-field-collation($prop)
        let $facet-options := 
        $prop/domain:navigation/search:facet-option
        let $ns := domain:get-field-namespace($prop)
        let $prop-nav := $prop/domain:navigation
        return
            <search:suggestion-source ref="{$prop/@name}">{
              element { fn:QName("http://marklogic.com/appservices/search","range") } {
                    attribute collation {$collation},
                    if ($type eq 'range') 
                    then attribute type { "xs:string" }
                    else (),
                    <search:element name="{$prop/@name}" ns="{$ns}" >{
                        (
                            if ($prop instance of attribute()) then
                              <search:attribute name="{$prop/@name}" ns="{$ns}"/> 
                            else ()
                        )
                    }</search:element>,
                    $facet-options
              }
            }</search:suggestion-source>
      let $sortOptions := 
         for $prop in $properties[domain:navigation/@sortable = "true"]
         let $collation := domain:get-field-collation($prop)
         let $ns := domain:get-field-namespace($prop)
         return
            ( <search:state name="{$prop/@name}">
                 <search:sort-order direction="ascending" type="{$prop/@type}" collation="{$collation}">
                  <search:element ns="{$ns}" name="{$prop/@name}"/>
                 </search:sort-order>
                 <search:sort-order>
                  <search:score/>
                 </search:sort-order>
            </search:state>,
            <search:state name="{$prop/@name}-descending">
                 <search:sort-order direction="descending" type="{$prop/@type}" collation="{$collation}">
                  <search:element ns="{$ns}" name="{$prop/@name}"/>
                 </search:sort-order>
                 <search:sort-order>
                  <search:score/>
            </search:sort-order>
          </search:state>)
          
      let $extractMetadataOptions := 
         for $prop in $properties[domain:navigation/@metadata = "true"]
         let $ns := domain:get-field-namespace($prop)
         return
            (<search:qname elem-ns="{$ns}" elem-name="{$prop/@name}"></search:qname>)

       (:Implement a base query:)   
       let $persistence := fn:data($domain-model/@persistence)
       let $baseQuery := 
            if ($persistence = ("document","singleton")) then 
               cts:document-query($domain-model/domain:document/text())
            else if($persistence = "directory") then
                cts:directory-query($domain-model/domain:directory/text())
            else ()
       let $addQuery := cts:and-query((
          $baseQuery,
          map:get($params,"_query")
          (:Need to allow to pass additional query through params:)
       ))
       let $options :=     
            <search:options>
                <search:return-query>{fn:true()}</search:return-query>
                <search:return-facets>{fn:true()}</search:return-facets>
                <search:additional-query>{$addQuery}</search:additional-query>
                <search:suggestion-source>{
                    $domain-model/search:options/search:suggestion-source/(@*|node())
                }</search:suggestion-source>

                {$constraints,
                 $suggestOptions,
                 $domain-model/search:options/search:constraint
                }
                <search:operator name="sort">{
                   $sortOptions,
                   $domain-model/search:options/search:operator[@name = "sort"]/*
                }</search:operator>
                {$baseOptions/search:operator[@name ne "sort"]}
                {$baseOptions/*[. except $baseOptions/(search:constraint|search:operator|search:suggestion-source)]}
                <search:extract-metadata>{$extractMetadataOptions}</search:extract-metadata>
             </search:options>
        return $options
};

(:~
 : Provide search interface for the model
 : @param $domain-model the model of the content type
 : @param $params the values to fill into the search
 : @return search response element
 :)
declare function model:search($domain-model as element(domain:model), $params as map:map)  
as element(search:response)
{
   let $query as xs:string* := map:get($params, "query")
   let $sort as xs:string?  := map:get($params, "sort")
   let $sort-order as xs:string? := map:get($params, "sort-order")
   let $page as xs:integer  := (map:get($params, "pg"),1)[1] cast as xs:integer
   let $pageLength as xs:integer  := (map:get($params, "ps"),20)[1] cast as xs:integer
   let $start := (($page - 1) * $pageLength) + 1
   let $end := ($page * $pageLength)
   (:let $final := fn:concat($query," ",$sort)  :) 
   let  $final := (if($query) then $query else "", $sort)
   let $options := model:build-search-options($domain-model,$params)
   let $results := 
     search:search($final,$options,$start,$pageLength)
   return 
     <search:response>
     {attribute page {$page}}
     {$results/(@*|node())}
     {$options}
     </search:response>
};

(:~
 : Provide search:suggest interface for the model
 : @param $domain-model the model of the content type
 : @param $params the values to fill into the search
 : @return search response element
 :)
declare function model:suggest($domain-model as element(domain:model), $params as map:map)  
as xs:string*
{
   let $options := model:build-search-options($domain-model,$params)
   let $query := map:get($params,"query")
   let $limit := (map:get($params,"limit"),10)[1] cast as xs:integer
   let $position := (map:get($params,"position"),fn:string-length($query[1]))[1] cast as xs:integer
   let $focus := (map:get($params,"focus"),1)[1] cast as xs:integer
   return
       search:suggest($query,$options,$limit,$position,$focus)
};

(:~
 :  returns a reference given an id or field value.
 :)
declare function model:get-references($field as element(), $params as map:map) {
    let $refTokens := fn:tokenize(fn:data($field/@reference), ":")
    let $element := element {$refTokens[1]} { $refTokens[1] }
    return 
        typeswitch ($element) 
        case element(model) 
        return model:get-model-references($field,$params)
        case element(application)
        return model:get-application-reference($field,$params)
        default return ()
};

(:~
 : This function will call the appropriate reference type model to build 
 : a relationship between two models types.
 : @param $reference is the reference element that is used to contain the references
 : @param $params the params items to build the relationship
 :)
 declare function model:get-model-references($reference as element(domain:element), $params as map:map)
 as element()* 
 {
    let $fieldKey := domain:get-field-id($reference)
    let $name := fn:data($reference/@name)
    let $tokens := fn:tokenize($reference/@reference, ":")
    let $type := $tokens[2]
    let $path :=config:get-base-model-location($type)
    let $ns := "http://xquerrail.com/model/base"
    let $funct := xdmp:function(fn:QName($ns,$tokens[3]),$path)
    return
        if(fn:function-available($tokens[3])) then
            let $domain-model := domain:get-domain-model($type)
            let $identity := domain:get-model-identity-field-name($domain-model)
            let $key := domain:get-model-identity-field-name($domain-model)  
            return
                for $id at $pos in map:get($params,$fieldKey)
                let $newParams := map:map()
                let $_ := if($key) then
                            map:put($newParams,$key,$id)
                          else ()
                return 
                    xdmp:apply($funct, $domain-model,$newParams)   
        else fn:error(xs:QName("ERROR"), "No Reference function avaliable.")
 };
 
 
(:~ 
 : This function will create a sequence of nodes that represent each
 : model for inlining in other references. 
 : @param $ids a sequence of ids for models to be extracted
 : @return a sequence of packageType
 :)
declare function model:reference($domain-model as element(domain:model), $params as map:map) 
as element()?
{
    let $keyLabel := fn:data($domain-model/@keyLabel)
    let $key := fn:data($domain-model/@key)
    let $modelReference := model:get($domain-model,$params)
    let $modelReference := 
        if($modelReference) 
        then $modelReference
        else model:getByReferenceKeyLabel($domain-model,$params)
    let $name := fn:data($domain-model/@name)
    let $ns := $domain-model/@namespace
    let $qName := fn:QName($ns,$name)
    return
        if($modelReference) then
             element { $qName } {
                 attribute ref-type { "model" },
                 attribute ref-uuid { $modelReference/(@*|*:uuid)/text() },
                 attribute ref-id   { fn:data($modelReference/(@*|node())[fn:local-name(.) = $key])},
                 attribute ref      { $name },
                 fn:data($modelReference/node()[fn:local-name(.) = $keyLabel])
             }
        else () 
         (:fn:error(xs:QName("INVALID-REFERENCE-ERROR"),"Invalid Reference", fn:data($domain-model/@name)):)
};

(:~
 :
 :)
declare  function model:get-application-reference($field,$params){
   let $reference := fn:data($field/@reference)
   let $ref-tokens := fn:tokenize($reference,":")
   let $ref-parent   := $ref-tokens[1]
   let $ref-type     := $ref-tokens[2]
   let $ref-action   := $ref-tokens[3]
   let $localName := fn:data($field/@name)
   let $ns := ($field/@namespace,$field/ancestor::domain:model/@namespace)[1]
   let $qName := fn:QName($ns,$localName)
   return
      if($ref-parent eq "application" and $ref-type eq "model")
      then 
        let $domains := xdmp:value(fn:concat("domain:model-",$ref-action))
        let $key := domain:get-field-id($field)
        return
            for $value in map:get($params, $key)
            let $domain := $domains[@name = $value] 
            return
                if($domain) then
                     element { $qName } {
                         attribute ref-type { "application" },
                         attribute ref-id { fn:data($domain/@name)},
                         attribute ref { $field/@name },
                         fn:data($domain/@label)
                     }
                else ()
      else if($ref-parent eq "application" and $ref-type eq "class")
      then  xdmp:apply(xdmp:function("model",$ref-action),$ref-type)
      else fn:error(xs:QName("REFERENCE-ERROR"),"Invalid Application Reference",$ref-action)
 };
 (:~
  :
  :)
 declare  function model:get-application-reference-values($field){
   let $reference := fn:data($field/@reference)
   let $ref-tokens := fn:tokenize($reference,":")
   let $ref-parent   := $ref-tokens[1]
   let $ref-type     := $ref-tokens[2]
   let $ref-action   := $ref-tokens[3]
   let $localName := fn:data($field/@name)
   let $ns := domain:get-field-namespace($field)
   let $qName := fn:QName($ns,$localName)
   return
      if($ref-parent eq "application" and $ref-type eq "model")
      then 
        let $domains := xdmp:value(fn:concat("domain:model-",$ref-action))
        return
           $domains
      else if($ref-parent eq "application" and $ref-type eq "class")
      then  xdmp:apply(xdmp:function("model",$ref-action),$ref-type)
      else fn:error(xs:QName("REFERENCE-ERROR"),"Invalid Application Reference",$ref-action)
 };

(:~ 
: This is a function that will validate the params with the domain model
: @param domain-model the model to validate against
: @param $params the params to validate 
: @return return a set of validation errors if any occur.
 :)
declare function model:validate-params($domain-model as element(domain:model), $params as map:map,$mode as xs:string)
as element(validationError)*
{
   let $unique-constraints := domain:get-model-unique-constraint-fields($domain-model)
   let $unique-search := domain:get-model-unique-constraint-query($domain-model,$params,$mode)
   return
      if($unique-search) then 
        for $v in $unique-constraints
        let $param-value := domain:get-field-param-value($v,$params)
        return         
        <validationError>
            <type>Unique Constraint</type>
            <error>Instance is not unique.Field:{fn:data($v/@name)} Value: {$param-value}</error>
        </validationError>
      else (),
   let $uniqueKey-constraints := domain:get-model-uniqueKey-constraint-fields($domain-model)
   let $uniqueKey-search := domain:get-model-uniqueKey-constraint-query($domain-model,$params,$mode)
   return
      if($uniqueKey-search) then  
        <validationError>
            <type>UniqueKey Constraint</type>
            <error>Instance is not unique. Keys:{fn:string-join($uniqueKey-constraints/fn:data(@name),", ")}</error>
        </validationError>
      else (),      
   for $element in $domain-model//(domain:attribute | domain:element)
   let $name := fn:data($element/@name)
   let $key := domain:get-field-id($element)
   let $type := domain:resolve-datatype($element)
   let $value := domain:get-field-param-value($element,$params)
   let $occurence := $element/@occurrence
   return
        (
        if( fn:data($occurence) eq "?" and fn:not(fn:count($value) <= 1) )  then
            <validationError>
                <element>{$name}</element>
                <type>{fn:local-name($occurence)}</type>
                <typeValue>{fn:data($occurence)}</typeValue>
                <error>The value of {$name} must have zero or one value.</error>
            </validationError>
        else if( fn:data($occurence) eq "+" and fn:not(fn:count($value) = 1) ) then 
             <validationError>
                <element>{$name}</element>
                <type>{fn:local-name($occurence)}</type>
                <typeValue>{fn:data($occurence)}</typeValue>
                <error>The value of {$name} must contain exactly one.</error>
            </validationError>
        else (),
        
        for $attribute in $element/domain:constraint/@*
        return
            typeswitch($attribute)
            case attribute(required) return
                if(fn:data($attribute) = "true" and fn:not(fn:exists($value))) then 
                    <validationError>
                        <element>{$name}</element>
                        <type>{fn:local-name($attribute)}</type>
                        <typeValue>{fn:data($attribute)}</typeValue>
                        <error>The value of {$name} can not be empty.</error>
                    </validationError>
                else ()
            case attribute(minLength) return
                if(xs:integer(fn:data($attribute)) > fn:string-length($value)) then
                        <validationError>
                            <element>{$name}</element>
                            <type>{fn:local-name($attribute)}</type>
                            <typeValue>{fn:data($attribute)}</typeValue>
                            <error>The length of {$name} must be longer than {fn:data($attribute)}.</error>
                        </validationError>
                    else ()
            case attribute(maxLength) return
                if(xs:integer(fn:data($attribute)) < fn:string-length($value)) then
                    <validationError>
                        <element>{$name}</element>
                        <type>{fn:local-name($attribute)}</type>
                        <typeValue>{fn:data($attribute)}</typeValue>
                        <error>The length of {$name} must be shorter than {fn:data($attribute)}.</error>
                    </validationError>
                else ()
            case attribute(minValue) return
               let $attributeValue := xdmp:value(fn:concat("fn:data($attribute) cast as ", $type))
               let $value := xdmp:value(fn:concat("$value cast as ", $type))
               return
                   if($attributeValue > $value) then
                        <validationError>
                             <element>{$name}</element>
                             <type>{fn:local-name($attribute)}</type>
                             <typeValue>{fn:data($attribute)}</typeValue>
                             <error>The value of {$name} must be greater than {$attributeValue}.</error>
                         </validationError>
                    else ()
            case attribute(maxValue) return
               let $attributeValue := xdmp:value(fn:concat("fn:data($attribute) cast as ", $type))
               let $value := xdmp:value(fn:concat("$value cast as ", $type))
               return
                   if($attributeValue < $value) then
                        <validationError>
                             <element>{$name}</element>
                             <type>{fn:local-name($attribute)}</type>
                             <typeValue>{fn:data($attribute)}</typeValue>
                             <error>The value of {$name} must be less than {$attributeValue}.</error>
                         </validationError>
                    else ()
             case attribute(inList) return
                let $options := $domain-model/domain:optionlist[@name = fn:data($attribute)]/domain:option/text()
                return
                    if(fn:not($options = $value)) then
                        <validationError>
                            <element>{$name}</element>
                            <type>{fn:local-name($attribute)}</type>
                            <typeValue>{fn:data($attribute)}</typeValue>
                            <error>The value of {$name} must be one of the following values [{fn:string-join($options,",")}].</error>
                        </validationError>
                     else ()
            case attribute(pattern) return
                    if(fn:not(fn:matches($value,fn:data($attribute)))) then
                        <validationError>
                            <element>{$name}</element>
                            <type>{fn:local-name($attribute)}</type>
                            <typeValue>{fn:data($attribute)}</typeValue>
                            <error>The value of {$name} must match the regular expression {fn:data($attribute)}.</error>
                        </validationError>
                     else ()
            default return ()
            )
};

(:~
 :
 :)
declare function model:put($domain-model as element(domain:model), $body as node()) 
{   
    let $params := model:build-params-map-from-body($domain-model,$body)
    return 
        model:create($domain-model,$params)
};

(:~
 : 
 :)
declare function model:post($domain-model as element(domain:model), $body as node())  {
    let $params := model:build-params-map-from-body($domain-model,$body)
    return 
        model:update($domain-model,$params)
};

(:~
 :  Takes a simple xml structure and assigns it to a map
 :  Does not handle nested content models
 :)
declare function model:build-params-map-from-body(
    $domain-model as element(domain:model), 
    $body as node()
) {
    let $params := map:map()
    let $body := if($body instance of document-node()) then $body/element() else $body
    let $_ := 
        for $xmlNode in $body/element()
        return
            map:put($params,fn:local-name($xmlNode),$xmlNode/node()/fn:data(.))
    return $params    
};

declare function model:convert-to-map(
    $domain-model as element(domain:model), 
    $current as node()
) {
    let $params := map:map()
    let $_ := 
      for $field in $domain-model//(domain:element|domain:attribute)
        let $field-name := domain:get-field-name-key($field)
        let $xpath := fn:string-join(domain:get-field-xpath($field), "")
        let $value := xdmp:value("$current" || $xpath || "/text()")
        return 
          map:put($params, domain:get-field-name-key($field), $value)
    return $params
};

(:~
 :  Builds the value for a given field type.  
 :  This ensures that the proper values are set for the given field
 :)
declare function model:build-value(
  $field as element(),
  $value as item()*,
  $current as item()*)
{
  let $localName := fn:data($field/@name)
  let $ns := domain:get-field-namespace($field)
  let $qName := fn:QName($ns,$localName)
  let $qtype := element {xs:QName(fn:data($field/@type))} { fn:data($field/*) }
  return
    typeswitch($qtype)
    case element(identity) return 
        if(fn:data($current)) 
        then fn:data($current)
        else model:get-identity()
    case element(reference) return
        let $fieldKey := domain:get-field-id($field)
        let $map := map:map()
        let $_ := map:put($map, $fieldKey, $value)
        return
            for $ref in model:get-references($field,$map)
            return 
            element { fn:QName($ns, $localName) } {
                $ref/@*,
                $ref/text()
            }
    case element(instance-of) return ()
    case element(update-timestamp) return 
        fn:current-dateTime()
    case element(update-user) return  
        xdmp:get-current-user()
    case element(create-timestamp) return 
        if(fn:data($current))
        then fn:data($current)
        else fn:current-dateTime()
    case element(create-user) return 
        if(fn:data($current))
        then fn:data($current)
        else xdmp:get-current-user()
    case element(schema-element) return 
        $value
    case element(query) return 
        $value
    default return 
        fn:data($value) 
};

(:~
 : Finds any element by a field name.  Important to only pass field names using special syntax
 :  "fieldname==" Equality
 :  "!fieldname=" Not Equality
 :  "fieldname>"  Greater Than (range only)
 :  "fieldname<"  Less Than (range only)
 :  "fieldname>=" Greater Than Equal To (range only)
 :  "fieldname<=" Less Than Equal To
 :  "fieldname.."  Between two values map must have 2 values of type assigned to field
 :  "!fieldname.." Negated between operators
 :  "fieldname*="  Word Wildcard Like Ex
 :  "!name*=" Any word or default
 :  "fieldname"  - performs a value query
 :  "join" 
 :)
declare function model:find($domain-model as element(domain:model),$params as map:map) {
   
    let $search := model:find-params($domain-model,$params)
    let $persistence := $domain-model/@persistence
    let $name := $domain-model/@name
    let $namespace := domain:get-field-namespace($domain-model)
    let $model-qname := fn:QName($namespace,$name)
    let $found  := 
        if ($persistence = 'document') then
            let $path := $domain-model/domain:document/text() 
            return
                fn:doc($path)/*/*[cts:contains(.,cts:and-query(($search)))]
        else if($persistence = 'directory') then 
                cts:search(fn:collection(),cts:element-query($model-qname, $search))       
        else fn:error(xs:QName("INVALID-PERSISTENCE"),"Invalid Persistence", $persistence)
   return $found        
};
(:~
 :  "fieldname==" Equality
 :  "fieldname!=" Not Equality
 :  "fieldname>"  Greater Than (range only)
 :  "fieldname<"  Less Than (range only)
 :  "fieldname>=" Greater Than Equal To (range only)
 :  "fieldname<=" Less Than Equal To
 :  "fieldname.."  Between two values map must have 2 values of type assigned to field
 :  "!fieldname.." Negated between operators
 :  "fieldname*="  Word Wildcard Like Ex
 :  "!name*=" Any word or default
 :  "fieldname"  - performs a value query
 :)
declare function find-params($model as element(domain:model),$params as map:map) {
   let $queries := 
    for $k in map:keys($params)[fn:not(. = "_join")]
        let $parts    := fn:analyze-string($k, "^(\i\c*)(==|!=|>=|>|<=|<|\.\.|)?$")
        let $opfield  := $parts/*:match/*:group[@nr eq 1]
        let $operator := $parts/*:match/*:group[@nr eq 2]
        let $field    := domain:get-model-field($model,$opfield)
        let $stype    := ($field/domain:navigation/domain:searchType,"value")[1]
        let $ns       := domain:get-field-namespace($field)
        let $qname    := fn:QName($ns,$field/@name)
        let $is-reference
                      := $field/@type="reference"
        let $query    := 
          if($operator eq "==" and fn:not($is-reference)) then 
                if($stype eq "range" ) 
                then cts:element-range-query($qname,"=",map:get($params,$k))
                else cts:element-value-query($qname,map:get($params,$k))
          else if($operator eq "=="  and $is-reference) then 
               (:is a reference process as such:)
               if($stype eq "range") 
               then cts:element-attribute-range-query($qname,xs:QName("ref-id"), "=", map:get($params,$k))
               else cts:element-attribute-value-query($qname,xs:QName("ref-id"),map:get($params,$k))
            else if($operator eq "!=") then
               if($stype eq "range") 
               then cts:element-range-query($qname,"!=",map:get($params,$k))
               else cts:not-query(cts:element-value-query($qname,map:get($params,$k))) 
            else if($operator = (">",">=","<=","<"))then   
               if($stype eq "range") 
               then  cts:element-range-query($qname,$operator,map:get($params,$k))
               else fn:error(xs:QName("FIND-RANGE-NOT-VALID"),"Must enable range index for field using operator",fn:string($field/@name)) 
            else if($operator eq "..") then
              if($stype eq "range") 
              then cts:and-query((
                      cts:element-range-query($qname,">=",map:get($params,$k)[1]),
                      cts:element-range-query($qname,"<=",map:get($params,$k)[2])
                     ))
              else fn:error(xs:QName("FIND-RANGE-NOT-VALID"),"Must enable range index for field using operator",fn:string($field/@name))
          else if($operator eq "*=")
                then cts:element-word-query($qname,map:get($params,$k))
                else cts:element-word-query($qname,map:get($params,$k))
      return 
         $query
  let $join := (map:get($params,"_join"),"and")[1]  
  return 
    if($join eq "or") 
    then cts:or-query($queries)
    else cts:and-query(($queries))
};

declare function partial-update(
    $model as element(domain:model),
    $updates as map:map
 ) {
    let $current := model:get($model,$updates)
    let $identity-field := domain:get-model-identity-field-name($model)
    return
        for $upd-key in map:keys($updates)
        let $context := $model//(domain:element|domain:attribute)[@name eq $upd-key]
        let $key   := domain:get-field-id($context)
        let $current-value := domain:get-field-value($context,$key,$current)
        let $build-node := model:recursive-build($context,$current-value,$updates,fn:true())
        where $context/@name ne $identity-field
        return
            xdmp:node-replace($current-value,$build-node)
};
(:~
 :  Finds particular nodes based on a model and updates the values
 :)
declare function model:find-and-update($model,$params) {
   ()
};
(:~
 : Collects the parameters 
 :)
(:
declare function model:build-find-and-update-params(   
    $model,
    $params) {
  let $final-map := map:map()
  let $upd-map := map:map()
  let $del-map := map:map()
  let $ins-map := map:map()
  let $col-map := map:map()
  let $_ := 
    for $k in map:keys($params) 
    let $t := fn:tokenize($k,":")
    return
      switch($t[1])
       (:Query:) case "q" return map:put($final-map,"query",$
       (:Update:)case "u" return map:put($
       (:Delete:)case "d" return 
       (:Insert:)case "i" return
       (:Collection:)case "c" return 
  return $update-map 
};:)

declare function model:export(
  $model as element(domain:model),
  $params as map:map
) as element(results) {
  model:export($model, $params, ())
};

(:~
 : Returns if the passed in _query param will be used as search criteria
 : $params support all model:list-params parameters
 : $fields optional return field list (must be marked as exportable=true)
~:)
declare function model:export(
  $model as element(domain:model),
  $params as map:map,
  $fields as xs:string?
) as element(results) {
  let $results := model:list($model, $params)
  let $filter-mod := $model
  let $convert-attributes := xs:boolean(map:get($params, "_convert-attributes"))
  let $export-fields := (
    domain:get-field-name-key(domain:get-model-identity-field($model)),
    if ($fields) then 
      for $field in $model//*[domain:navigation/@exportable="true" and domain:get-field-name-key(.) = $fields]
      return
        domain:get-field-name-key($field)
    else 
      for $field in $model//*[domain:navigation/@exportable="true"](:/@name:)
      return
        domain:get-field-name-key($field)
  )
  return
    element results {
    element header {
      element {fn:QName(domain:get-field-namespace($filter-mod),$filter-mod/@name)} {
        for $field in $filter-mod//(domain:element|domain:attribute)[domain:get-field-name-key(.) = $export-fields]
        return element {fn:QName(domain:get-field-namespace($field), domain:get-field-name-key($field))} {fn:data($field/@label)}
      }
    },
    element body {
      for $f in $results/*[fn:local-name(.) eq $filter-mod/@name]
      return
        element {fn:node-name($f)} {
          convert-attributes-to-elements(domain:get-field-namespace($filter-mod), $f/@*[name(.) = $export-fields], $convert-attributes),
          serialize-to-flat-xml(domain:get-field-namespace($f), $model, $f)[fn:local-name(.) = $export-fields]
        }
    }
  }

};

declare %private function convert-attributes-to-elements($namespace as xs:string, $attributes, $convert-attributes) {
  if ($convert-attributes) then
    for $attribute in $attributes
    return
      element {fn:QName($namespace, fn:name($attribute))} {xs:string($attribute)}
  else
    $attributes
};

declare %private function serialize-to-flat-xml(
  $namespace as xs:string,
  $model as element(domain:model),
  $current as node()
) {
  let $map := model:convert-to-map($model, $current)
  return
    for $key in map:keys($map)
    return
      element { fn:QName($namespace, $key) } { map:get($map, $key) }
};

declare %private function convert-flat-xml-to-map(
  $model as element(domain:model),
  $current as node()
) as map:map {
  map:new((
    map:entry(domain:get-field-name-key(domain:get-model-identity-field($model)), domain:get-field-value(domain:get-model-identity-field($model), $current)),
    for $field in $current/*
    return
      map:entry(fn:local-name($field), $field/text()) 
  ))
};

declare function model:import(
  $model as element(domain:model),
  $dataset as element(results)
) as empty-sequence() {
  let $_ :=
    for $doc in $dataset/body/*
      let $map := convert-flat-xml-to-map($model, $doc)
      return model:update-partial($model, $map)
  return ()
};