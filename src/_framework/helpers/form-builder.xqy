xquery version "1.0-ml";

module namespace form = "http://www.xquerrail-framework.com/helper/form-builder";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:
import module namespace request = "http://www.xquerrail-framework.com/request"
at "/_framework/request.xqy";
:)

import module namespace domain = "http://www.xquerrail-framework.com/domain" 
at "/_framework/domain.xqy";

import module namespace json = "http://marklogic.com/json" 
at "/_framework/lib/mljson.xqy";

import module namespace js    = "http://www.xquerrail-framework.com/helper/javascript"
at "/_framework/helpers/javascript.xqy";

import module namespace response = "http://www.xquerrail-framework.com/response"
at "/_framework/response.xqy";

import module namespace base = "http://www.xquerrail-framework.com/model/base"
  at "/_framework/base/base-model.xqy";

declare option xdmp:output "indent=yes";
declare option xdmp:output "method=xml";
declare option xdmp:ouput "omit-xml-declaration=yes";
declare option xdmp:mapping "false";

declare variable $FORM-MODE-EDIT := "edit";
declare variable $FORM-MODE-NEW  := "new";
declare variable $FORM-MODE-READONLY := "readonly";
declare variable $FORM-SIZE-CLASS    := "medium";

declare variable $FORM-MODE := "";

declare function form:size($size as xs:string) {
   xdmp:set($FORM-SIZE-CLASS,$size)
};

declare function form:mode($mode as xs:string) {
  xdmp:set($FORM-MODE,$mode)
};

declare function form:get-field-name($field as node()) {
    domain:get-field-id($field)  
};

declare function form:initialize-response($response) {
    response:initialize($response)
};

declare function form:build-form(
 $domain-model as node(),
 $response as map:map?)
as item()*
{
    let $init := response:initialize($response)
    let $_ := xdmp:log(("form:build-form::",response:body()),"debug")
    for $field in $domain-model/(domain:attribute|domain:element|domain:container)
    return 
      form:build-form-field($field)
};

declare function form:form-field(
    $domain-model as element(domain:model),
    $fieldname as xs:string
) {
    for $field in $domain-model//(domain:attribute|domain:element|domain:container)[@name = $fieldname]
    return 
      form:build-form-field($field)
};

declare function form:build-form-field(
    $field as node()
) {
   let $value :=  form:get-value-from-response($field)
   let $type := (fn:data($field/domain:ui/@type),fn:data($field/@type))[1]
   let $label := fn:data($field/@label)
   let $repeater := 
       if(fn:data($field/domain:ui/@repeatable) = 'true') then
       (
        <a href="#" onclick="return repeatAdd(this,'{domain:get-field-id($field)}', '{$label}');" class="ui-icon ui-icon-plus" style="display:inline-block">+</a>,
        <a href="#" onclick="return repeatRemove(this,'{domain:get-field-id($field)}', '{$label}');" class="ui-icon ui-icon-minus" style="display:inline-block">-</a>
       )
       else ()
   return
   typeswitch($field)
     case element(domain:container) return
       <div class="row"> 
        <h4>{fn:data(($field/@label,$field/@name)[1])}</h4>
        <div class="span12">
          
        { 
            for $containerField in $field/(domain:attribute|domain:element|domain:container)
            return
                form:build-form-field($containerField) 
        }</div>
     </div>/*
     case element(domain:element) return
       if ($repeater and $value) then 
            for $v in $value
            return
             (form:render-control($field,$v),$repeater) 
       else
             (form:render-control($field,$value),$repeater)
     case element(domain:attribute) return
       if ($repeater and $value) then 
            for $v in $value
            return
            <div class="control-group type_{$type}">{ (form:render-control($field,$v),$repeater) }</div>
       else
            <div class="control-group type_{$type}">{ (form:render-control($field,$value),$repeater) }</div>
     default return ()
};

declare function form:render-control($field,$value)
{
  let $type := (fn:data($field/domain:ui/@type),fn:data($field/@type))[1]
  let $qtype := element {fn:QName("http://www.w3.org/1999/xhtml",$type)} { $type }
  return
    typeswitch($qtype)

     (: Complex Element :)
      case element(schema-element) return form:render-complex($field,$value)
      case element(html-editor) return form:render-complex($field,$value)
      case element(textarea) return form:render-complex($field,$value)
      case element(reference) return form:render-reference($field,$value)
      case element(grid) return form:build-child-grid($field,$value)

      (:Text Elements:)
      case element(identity) return render-hidden($field,$value)
      case element(string) return render-text($field,$value)
      case element(text) return render-text($field,$value)
      case element(integer) return render-text($field,$value)
      case element(long) return render-text($field,$value)
      case element(decimal) return render-text($field,$value)
      case element(float) return render-text($field,$value)
      case element(anyURI) return render-text($field,$value)
      case element(yearMonth) return render-text($field,$value)
      case element(monthDay) return render-text($field,$value)
      
      case element(boolean) return render-checkbox($field,$value)
      case element(password) return form:render-password($field,$value)
      case element(email) return form:render-email($field,$value)
      
      (:Choice Elements:)
      case element(list) return form:render-choice($field,$value)
      case element(radiolist) return form:render-list($field,$value)
      case element(checkboxlist) return form:render-list($field,$value)
      case element(choice) return form:render-choice($field,$value)
      case element(entity) return form:render-entity($field,$value)
      case element(country) return form:render-country($field,$value)
      case element(locale) return form:render-locale($field,$value)
      
      (:Date Time Controls:)
      case element(date) return form:render-date($field,$value)
      case element(dateTime) return form:render-dateTime($field,$value)
      case element(time) return form:render-time($field,$value)
     
      (:Repeating Controls:)
      case element(collection) return form:render-collection($field,$value)
      case element(repeated) return form:render-repeated($field,$value)
      
      (:Button Controls:)
      case element(hidden) return form:render-hidden($field,$value)
      
      case element(button) return form:render-button($field,$value)
      case element(submit) return form:render-submit($field,$value)
      case element(clear) return form:render-clear($field,$value)
      
      (:Other Controls:)
      case element(referenceLookup) return form:render-lookup($field,$value)
      case element(csrf) return form:render-csrf($field,$value)
      case element(binary) return form:render-binary($field,$value)
      case element(file) return form:render-binary($field,$value)
      case element(fileupload) return form:render-binary($field,$value)

     (:Custom Rendering:)
      case element() return form:render-custom($field,$value)
      
      default return <div class="error">No Render for field type {$type}.</div>
};

declare function form:get-value-from-response($field as element()) {

    let $model := $field/ancestor::domain:model
    let $name := fn:data($field/@name)
    let $ns := domain:get-field-namespace($field)
    
    (: Verify you only pull the approprite node just incase the body is a sequence :)
    let $node := response:body()//*[fn:local-name(.) = $name]
    let $_ := xdmp:log(("field:node::",$node),"debug")
    let $value := 
        if($field/@type = ("reference","binary")) 
        then $node
        else if($field/@type = "schema-element") then 
          $node/node()
        else 
            if($node) 
            then fn:data($node)
            else fn:data($field/@default)
    return 
        $value
};

declare function form:get-value-by-name-from-response($name as xs:string) {
    let $value := response:body()//*[fn:string(fn:node-name(.)) = $name]
    return 
        $value
};

declare function form:render-before($field)
{
  if($field/@label and fn:not($field/domain:ui/@type = "hidden")) 
  then 
    <label for="{form:get-field-name($field)}" class="control-label">
        {fn:data($field/@label)}
    </label> 
  else ()
};

declare function form:render-after($field)
{
    let $type := ($field/domain:ui/@type,$field/@type)[1]
    let $id   := domain:get-field-id($field)
    let $qtype := element {$type} {$type}
    return
      typeswitch($qtype)
        case element(html-editor) return 
            <script type="text/javascript">
               jQuery(function(){{
                  $("#{$id}").elrte({js:o((
                     js:p("height",200),
                     js:p("toolbar","compact")
                  ))});
               }});
            </script>
         case element(code-editor) return 
            <script type="text/javascript">
              
            </script>       
       default return ()
};

declare function form:render-attributes($field)
{(
    if(($field/domain:navigation/@editable = 'false' and $FORM-MODE = "edit")
        or ($field/domain:navigation/@newable = 'false' and $FORM-MODE = "new")
        or ($FORM-MODE = "readonly")
       ) 
    then attribute readonly { "readonly" } 
    else if($field/@occurrence = ("*","+")) then
        attribute multiple {"multiple"}
    else (),
    if($field/@type eq "boolean")
    then attribute class {"field"}
    else if($field/@type eq "schema-element" or $field/domain:ui/@type = "textarea")
         then  attribute class {("field", "textarea",$FORM-SIZE-CLASS,$field/@name)}
    else attribute class {("field",$FORM-SIZE-CLASS,$field/@type,$field/@name)},
    attribute placeholder {($field/@label,$field/@name)[1]},
    let $constraint  := $field/domain:constraint
    return (
        if($constraint/@required = "true")                then attribute required  {$constraint/@required eq "true"}    else (),
        if($constraint/@minLength castable as xs:integer) then attribute minlength {xs:integer($constraint/@minLength)} else (),
        if($constraint/@maxLength castable as xs:integer) then attribute maxlength {xs:integer($constraint/@maxLength)} else (),
        if($constraint/@minValue ne "" )                  then attribute minValue  {xs:integer($constraint/@minValue)}  else (),
        if($constraint/@maxValue ne "")                   then attribute maxValue  {xs:integer($constraint/@maxValue)}  else ()
    )
)};

declare function form:render-validation($field) {
    let $constraint  := $field/domain:constraint
    return (
        if($constraint/@required = "true")                then attribute required  {$constraint/@required eq "true"}    else (),
        if($constraint/@minLength castable as xs:integer) then attribute minlength {xs:integer($constraint/@minLength)} else (),
        if($constraint/@maxLength castable as xs:integer) then attribute maxlength {xs:integer($constraint/@maxLength)} else (),
        if($constraint/@minValue ne "" )                  then attribute minValue  {xs:string($constraint/@minValue)}   else (),
        if($constraint/@maxValue ne "")                   then attribute maxValue  {xs:string($constraint/@maxValue)}   else ()
    )
};

declare function form:render-values($field,$value)
{
 let $list  := (
        $field/ancestor::domain:model/domain:optionlist[@name = $field/domain:constraint/@inList],
        domain:get-optionlist($field/domain:constraint/@inList)
 )[1]
 let $is-multi := $field/@occurrence  = ("+","*")
 let $default  := $field/@default
 let $value    := if($value) then $value else $default
 return 
 if($list) then
    for $option in $list/domain:option
    return
        <option value="{$option/text()}">
            {   if($value = $option/text()) then
                    attribute selected {"selected" }
                else (),
                (fn:data($option/@label),$option/text())[1]
            }
        </option>
  else 
    if(fn:data($field/@type = "boolean")) 
    then (   
            attribute value {$value},
            if(xs:boolean($value) eq fn:true()) 
            then attribute checked {"checked"}
            else ()
    ) else  attribute value {$value}
};

(:~
 : Custom Rendering of controls
 : Formats : 
 :   (application):(helper|model|tag):function-name($field,$value)
 :   The method should take a field and value
~:)
declare function form:render-custom($field,$value)
{
  let $renderer := $field/domain:ui/@renderer
  let $context := fn:tokenize($renderer,":")
  let $source  := $context[1]
  let $type    := $context[2]
  let $action  := $context[3]
  let $apply   := ()
  return 
     $apply
};
(:~
 : Function binds controls to their respective request data 
 : from the request map;
~:)
declare function form:render-text($field,$value)
{
  <div class="control-group">{
       form:render-before($field),
       <div class="controls">{       
            if($field/domain:constraint/@inList) then
            <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}">
            {form:render-attributes($field)}
            {form:render-values($field,$value)}
            </select>
            else 
            <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
            {form:render-attributes($field)}
            {form:render-values($field,$value)}
            </input>
       }</div>
       ,
       form:render-after($field)
  }</div>
};
(:~
 : Renders a list of radio boxes 
~:)
declare function form:render-list($field,$value) {
    let $type as xs:string := ($field/domain:ui/@type,$field/@type)[1]
    let $ui-type := 
        if($type = ("radio","radiolist")) 
        then "radio"
        else if($type = ("checkbox","checkboxlist")) 
        then "checkbox"
        else fn:error(xs:QName("FIELD-OPTION-TYPE-ERROR"),"Type is not value for renderlist",$type)        
    return (
       form:render-before($field), 
       if($field/domain:constraint/@inList) then 
         let $optionlist := domain:get-field-optionlist($field)
         for $option in $optionlist/domain:option
         let $label := (fn:data($option/@label),fn:data($option))[1]
         return (
         <label class="value control-label">
           <input name="{form:get-field-name($field)}" type="{$ui-type}">
           {form:render-attributes($field)}
           {attribute value {$option/text()}}
           {
            if($value = fn:data($option)) 
            then attribute checked {"checked"}
            else ()            
           }
           </input>
           {$label}
          </label>
          )
       else if($field/@type = "reference") then 
            ()
       else ()
       ,
       form:render-after($field)
  )          
};
declare function form:render-checkbox-value(
$field as element(),
$mode as xs:string,
$value as item()*
) {  
  if($mode eq "true")
  then attribute value { xs:string($value) eq "true"}
  else attribute value {xs:string($value) eq "false"}
};

declare function form:render-checkbox($field,$value)
{
  <div class="control-group">{
   form:render-before($field),
    <div class="controls">     
       <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="radio" value="true">
       {form:render-attributes($field)}
       {
        if($value castable as xs:boolean) 
        then if($value cast as xs:boolean  = fn:true()) then attribute checked{"checked"} else ()
        else () 
       }
       True
       </input>
       <input name="{form:get-field-name($field)}" type="radio" value="false"  >
       {form:render-attributes($field)}
       {if($value castable as xs:boolean) 
        then if($value cast as xs:boolean  = fn:false()) then attribute checked{"checked"} else ()
        else () 
       }
       False
       </input>      
       {form:render-after($field)}
       </div>
    }</div>
};

declare function form:render-money($field,$value)
{(
           form:render-before($field), 
           <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
           {form:render-attributes($field)}
           {form:render-values($field,$value)}
           </input>,
           form:render-after($field)
)};

declare function form:render-number($field,$value)
{
(
   form:render-before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)
};
declare function form:render-password($field,$value)
{(
   form:render-before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="password">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)};

declare function form:render-email($field,$value)
{(
   form:render-before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)};

declare function form:render-search($field,$value)
{(
       form:render-before($field), 
       <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
       {form:render-attributes($field)}
       {form:render-values($field,$value)}
       </input>,
       form:render-after($field)
)};

declare function form:render-url($field,$value)
{(
       form:render-before($field), 
       <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
       {form:render-attributes($field)}
       {form:render-values($field,$value)}
       </input>,
       form:render-after($field)
)};

declare function form:render-choice($field,$value)
{(
       form:render-before($field), 
       <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}">
       {form:render-attributes($field)}
       {form:render-values($field,$value)}
       </select>,
       form:render-after($field)
)};

declare function form:render-entity($field,$value)
{(
       form:render-before($field), 
       <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}">
       {form:render-attributes($field)}
       {form:render-values($field,$value)}
       </select>,
       form:render-after($field)
)};

declare function form:render-country($field,$value)
{(
       form:render-before($field), 
       <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}">
       {form:render-attributes($field)}
       {form:render-values($field,$value)}
       </select>,
       form:render-after($field)
)};

declare function form:render-locale($field,$value)
{(
    form:render-before($field), 
    <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}">
    {form:render-attributes($field)}
    {form:render-values($field,$value)}
    </select>,
    form:render-after($field)
)};

declare function form:render-time($field,$value)
{ <div class="control-group">{
       form:render-before($field),
       <div class="controls">
         <div id="{form:get-field-name($field)}_time" class="bootstrap-timepicker input-append">
            <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text" data-format="hh:MM:ss">
            {form:render-attributes($field)}
            {form:render-values($field,$value)}
            </input>
            <span class="add-on"><i class="icon-time"></i></span>
         </div>
       </div>
       ,
       form:render-after($field)
  }</div>
};

declare function form:render-date($field,$value)
{  <div class="control-group">{
       form:render-before($field),
       <div class="controls">
         <div class="date input-append">
            <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text" data-date-format="yyyy-mm-dd">
            {form:render-attributes($field)}
            {form:render-values($field,$value)}
            </input>
            <span class="add-on"><i class="icon-calendar" data-date-icon="icon-calendar"> </i></span>
         </div>
       </div>
       ,
       form:render-after($field)
  }</div>
};

(:~
 : Function binds controls to their respective request data 
 : from the request map;
~:)
declare function form:render-dateTime($field,$value)
{
  <div class="control-group">{
       form:render-before($field),
       <div class="controls">
         <div id="{form:get-field-name($field)}_dateTime" class="dateTime input-append">
            <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text" data-date-format="yyyy-MM-dd hh:mm:ss">
            {form:render-attributes($field)}
            {form:render-values($field,$value)}
            </input>
            <span class="add-on"><i class="icon-calendar" data-date-icon="icon-calendar"> </i></span>
         </div>
       </div>
       ,
       form:render-after($field)
  }</div>
};

declare function form:render-collection($field,$value)
{(
   form:render-before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)};

declare function form:render-repeated($field,$value)
{(
   form:render-before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="text">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)};

declare function form:render-hidden($field,$value)
{(
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="hidden">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)};

declare function form:render-button($field,$value)
{(
   form:render-before($field), 
   <button name="{form:get-field-name($field)}" type="button">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </button>,
   form:render-after($field)
)};

declare function form:render-submit($field,$value)
{(
   form:render-before($field), 
   <button name="{form:get-field-name($field)}" type="submit">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </button>,
   form:render-after($field)
)};

declare function form:render-clear($field,$value)
{(
   form:render-before($field), 
   <button name="{form:get-field-name($field)}" type="clear">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </button>,
   form:render-after($field)
)};

declare function form:binary-content-type-icon($value) {
    let $content-type := $value/@content-type
    return 
      if($content-type and $content-type ne "")
      then fn:replace(fn:replace($content-type,"/","-"),"\.","")
      else "unknown"
};

declare function form:render-binary($field,$value) {
  <div class="control-group">
    {form:render-before($field)}
    <div class="controls">
         <div class="fileupload fileupload-new" data-provides="fileupload">
             <div class="input-append">
                 <div class="uneditable-input span3">
                     <i class="icon-file fileupload-exists"></i> 
                     <span class="fileupload-preview"></span></div>
                     <span class="btn btn-file">
                         <span class="fileupload-new icon-plus"></span>
                         <span class="fileupload-exists icon-edit"></span>
                           <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="file">
                             {form:render-attributes($field)}
                             {form:render-values($field,$value)}
                           </input>
                     </span>
                     <span class="btn fileupload-exists add-on" data-dismiss="fileupload">
                       <i class="icon-remove"></i>
                     </span>
                     <!--<a href="#" class="btn fileupload-exists add-on" data-dismiss="fileupload">
                     
                     </a>-->
                 </div>
          </div>
     </div>
     {form:render-after($field)}
  </div>
};

declare function form:render-csrf($field,$value)
{(
   form:render-before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" id="CSRFToken" type="hidden">
   {form:render-attributes($field)}
   {form:render-values($field,$value)}
   </input>,
   form:render-after($field)
)};

declare function form:render-schema-element($field,$value) 
{(
 <div class="control-group">{
  form:render-before($field),
  <div class="controls">  
    <textarea name="{form:get-field-name($field)}" id="{domain:get-field-id($field)}">
        { form:render-attributes($field) }
        { if( $value/element() or $value instance of element() and $value) then xdmp:quote($value) else $value}
     </textarea>
   </div>,
   form:render-after($field)
   }</div>
)};

declare function form:render-complex($field,$value) 
{(
  <div class="control-group">{ 
       form:render-before($field), 
       <div class="controls">
        <textarea name="{form:get-field-name($field)}" id="{domain:get-field-id($field)}">
            { form:render-attributes($field) }
            { if( $field/@type = "schema-element") then xdmp:quote($value) else $value}
         </textarea>
       </div>,
       form:render-after($field)
   }</div>
)};

declare function form:build-child-grid($field,$value) {
    let $fieldKey := form:get-field-name($field)
    
	let $fieldSchema := () (: js:o((
	   for $item in $field/domain:ui/domain:gridColumns/domain:gridColumn
       let $name := fn:data($item/@name)
       let $type := fn:data($item/@type)
	   return
	      js:p($name, 
	        js:o((js:p("type", js:string($type))
	      )))
    )):)
	
	let $columnSchema := 
	 js:a(
     	   for $item in $field/domain:ui/domain:gridColumns/domain:gridColumn
     	   let $name := fn:data($item/@name)
         	   let $label := (fn:data($item/@label),fn:data($field/@label),fn:data($field/@name))[1]
     	   let $type :=  (fn:data($item/@type), "string")[1]
     	   let $visible := 
     	      if($item/@type eq "hidden" or $field/@type eq "identity")
     	      then fn:false()
     	      else fn:true()
     	   return
              js:o((
                js:p("field",$name),
                js:p("title",$label),
                js:p("sortable",fn:true()),
                js:p("resizable",fn:true()),
                js:p("type",$type),
                js:p("visible",$visible)
              ))
	 )
	 
     let $modelData := json:xmlToJSON(
     <json type="array">{
        if($value instance of node()) then
         for $node in $value/element()
         return
         <item type="object">{$node/node()}</item>
        else ()
     }</json>)

	return
	
	(
     form:render-before($field), 
      <div class="complexGridWrapper">
           <div id="{$fieldKey}" class="complexGrid"></div>
           <script type="text/javascript">
                buildEditGrid('{$fieldKey}', {$modelData},   {$columnSchema}) 
           </script>
       </div>,
      form:render-after($field)
   )
};

declare function form:render-lookup($field,$value) {
    let $application := response:application()
    let $modelName := fn:tokenize(fn:data($field/@reference),":")[2]
    let $reference := fn:data($field/@reference)
    let $refTokens := fn:tokenize($reference,":")
    let $refParent   := $refTokens[1]
    let $refType     := $refTokens[2]
    let $refAction   := $refTokens[3]
    let $fieldName  := form:get-field-name($field)
    let $lookupReference := (
        fn:data($field/domain:ui/@lookupReference),
        domain:get-model-controller-name($refType)
        )[1]
    let $refController := 
        let $tokenz := fn:tokenize($lookupReference,":")
        return
          if(fn:count($tokenz) = 2) 
          then fn:concat("/",$tokenz[1],"/",$tokenz[2],".xml")
          else if(fn:count($tokenz) = 1) then
               fn:concat("/",$tokenz[1],"/lookup.xml")      
          else fn:error(xs:QName("LOOKUP-REFERENCE-ERROR"),"Unable to resolve reference",$tokenz)
    return
      <div class="lookupSelect control-group">
       {form:render-before($field)}  
       <div class="controls">
       <select id="{$fieldName}" name="{$fieldName}">
       {   (:Added validation Rendering:)
           form:render-validation($field),
           attribute readonly { "readonly" },
           if($field/@occurrence = ("*","+")) 
           then (
               attribute multiple { "multiple" },
               attribute class {("field", "lookup", $FORM-SIZE-CLASS,$field/@name  )}
               )
            else (
                attribute class {("field", "lookup", $FORM-SIZE-CLASS,$field/@name )}
            )
              
        }
        {
            (: Only use the current value if present :)
            if($refParent = 'model') then
               element option {
                    attribute value {$value/@ref-id},
                    attribute selected { "selected" },
                    $value/text()
               }
            else fn:error(xs:QName("INVALID_LOOKUP_TYPE"),"Lookup can only use type:model")
         }
       </select>
       {
        if(($field/domain:navigation/@editable = 'false' and $FORM-MODE = "edit")
                or ($field/domain:navigation/@newable = 'false' and $FORM-MODE = "new")
                or ($FORM-MODE = "readonly")
        )  then ()
        else
           <button id="{$fieldName}_button" class="lookup button" value="{$refController}" type="button"></button> 
       }
       </div>       
       {form:render-after($field)}
      </div>
};

declare function form:render-reference($field,$value) {
    let $application := response:application()
    let $modelName := fn:tokenize(fn:data($field/@reference),":")[2]
    let $reference := fn:data($field/@reference)
    let $refTokens := fn:tokenize($reference,":")
    let $refParent   := $refTokens[1]
    let $refType     := $refTokens[2]
    let $refAction   := $refTokens[3]
    let $form-mode := 
      if($FORM-MODE = "readonly") then "readonly" 
      else if($FORM-MODE = "new" and fn:not($field/domain:navigation/@newable = "false"))      then ()
      else if($FORM-MODE = "edit" and fn:not($field/domain:navigation/@editable = "false")) then ()
      else "readonly"
    return
    <div class="referenceSelect control-group">
           { form:render-before($field) }
       <div class="controls">    
           <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" >{   
                form:render-validation($field),
                if(($field/domain:navigation/@editable = 'false' and $FORM-MODE = "edit")
                    or ($field/domain:navigation/@newable = 'false' and $FORM-MODE = "new")
                    or ($FORM-MODE = "readonly")
                ) 
                then attribute readonly { "readonly" } 
                else (),
               if($field/@occurrence = ("*","+")) 
               then (
                   attribute multiple { "multiple" },
                   attribute class {("field", "select", $FORM-SIZE-CLASS, "multiselect",$field/@name )}
                   )
                else (
                    attribute class {("field", "select",$FORM-SIZE-CLASS,$field/@name )},
                    if($form-mode = "readonly") then () else <option value="">Please select {fn:data($field/@label)}</option>
                )
            }
            {
                (: Build Model Refrences using the lookup feature in the base model :)
                if($refParent = 'model') then
                     let $lookups := base:lookup(domain:get-domain-model($modelName),map:map())
                     return
                        if($form-mode = "readonly") 
                        then <option value="{$value/@ref-id}" selected="selected">{fn:string($value)}</option>
                        else 
                           for $lookup in $lookups/*:lookup
                           let $key := fn:normalize-space(fn:string($lookup/*:key))
                           let $label := $lookup/*:label/text()
                           return 
                             element option {
                                  attribute value {$key},
                                  if($value/@ref-id = $key) 
                                  then attribute selected { "selected" } 
                                  else (),
                                  $label
                             }
                (: Build Abstract Model References using the base model functions :)       
                else if($refParent = 'application') then  
                    if($refParent eq "application" and $refType eq "model")
                    then 
                      let $domains := xdmp:value(fn:concat("domain:model-",$refAction))
                      for $model in $domains
                      let $key := fn:data($model/@name)
                      let $label := fn:data($model/@label)
                      return
                          element option {
                              attribute value { $key },
                              if($value/@ref-id = $key) 
                              then attribute selected { "selected" }
                              else (),
                              $label
                          }
                     else ()
                else ()
             }
           </select>         
        </div>           
           { form:render-after($field) }
    </div>
};

(:~
 : Creates a grid column specification to be used in jqgrid control.
 :
~:)
declare function form:field-grid-column(
  $field as element()
) {
    let $model-name := fn:data($field/ancestor::domain:model/@name)
    let $name := fn:data($field/@name)
    let $fieldType := fn:local-name($field)
    let $label := fn:data($field/@label)
    let $dataType := fn:data($field/@type)
    let $listable :=  ($field/domain:navigation/@listable, $field/domain:navigation/@visible,"true")[1]
    let $colWidth := (fn:data($field/domain:ui/@gridWidth/xs:integer(.)),200)[1]
    let $sortable := ($field/domain:navigation/@sortable,"true")[1]
    return
    if($listable = "true") then
         js:o((
             js:p("name",$name),
             js:p("label",$label),
             js:p("index",$name),
             js:p("xmlmap",if($fieldType = "attribute") then "[" || $name || "]" else $name),
             js:p("jsonmap", $name),
             js:p("dataType",$dataType),
             js:p("resizable",fn:true()),
             js:p("fixed",fn:true()),
             js:p("sortable",$sortable),
             js:p("width",$colWidth),
             js:p("searchable",$field/domain:navigation/@searchable eq "true"),
             js:p("hidden",$field/domain:ui/@type eq "hidden" or 
                $field/domain:navigation/@listable eq "false"),
             if($field/domain:ui/@formatter ne "" and fn:exists($field/domain:ui/@formatter)) 
             then js:p("formatter",js:s($field/domain:ui/@formatter))
             else if($field/@occurrence = ("+","*")) then js:p("formatter",js:string("arrayFormatter"))
             else if($dataType eq "binary") then js:p("formatter",js:literal("binaryFormatter"))
             else if($dataType eq "boolean") then (js:p("formatter","checkbox"),js:p("align","center"))
             else ()             
         ))
     else ()
};

(:~
 :    Assigns validation constraints to input 
 :    Assumes the use of bassistance.de jquery.validation.js
~:)
declare function form:build-validation($model) {
  js:o((
    js:no("rules",(
        for $f in $model//(domain:element|domain:attribute|domain:container)
        let $constraint := $f/domain:constraint
        return
          if($constraint) 
          then js:no(form:get-field-name($f), (
            if($constraint/@required = "true") then js:p("required",$constraint/@required eq "true") else (),
            if($constraint/@minLength castable as xs:integer) then js:p("minlength",xs:integer($constraint/@minLength)) else (),
            if($constraint/@maxLength castable as xs:integer) then js:p("maxlength",xs:integer($constraint/@maxLength)) else (),
            if($constraint/@minValue ne "" )  then js:p("min",xs:integer($constraint/@minValue)) else (),
            if($constraint/@maxValue ne "")  then js:p("max",xs:integer($constraint/@maxValue)) else ()
            
          ))
          else ()
    ))
  ))
};

(:~
 : Builds a javascript context object that can be used to drive navigation
~:)
declare function form:context(
   $response as map:map
) {(
   response:initialize($response)[0],
   js:variable("context", 
        js:o((
           js:pair("application",response:application()),
           js:pair("controller", response:controller()),
           js:pair("action",response:action()),
           js:pair("view",response:view()),
           if(response:model())
           then 
              let $identityField := domain:get-model-identity-field(response:model())
              let $keyLabelField := domain:get-model-keyLabel-field(response:model())
              return (
              js:pair("currentId",domain:get-field-value($identityField,response:body())/fn:data(.)),
              js:pair("currentLabel",domain:get-field-value($keyLabelField,response:body())/fn:data(.)),
              js:pair("modelName",response:model()/@name),
              js:pair("modelId",domain:get-model-identity-field-name(response:model())),
              js:pair("modelKeyLabel",fn:string(domain:get-model-keyLabel-field(response:model())/@name)),
              js:pair("modelIdSelector",
               let $idField := domain:get-model-identity-field(response:model())
               return 
                 if($idField instance of element(domain:attribute)) 
                 then "[" || $idField/@name || "]"
                 else fn:string($idField/@name)
               )
           )
           else ()
        ))
   ))
};