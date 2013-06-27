xquery version "1.0-ml";
(:~
 : Base Edit Template used for rendering output
~:)
declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace domain = "http://www.xquerrail-framework.com/domain" at "/_framework/domain.xqy";
import module namespace form = "http://www.xquerrail-framework.com/helper/form-builder" at "/_framework/helpers/form-builder.xqy";
import module namespace response = "http://www.xquerrail-framework.com/response" at "/_framework/response.xqy";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
let $domain-model := response:model()
let $form-mode := form:mode("new")
let $id-field := domain:get-model-identity-field($domain-model)
let $id-field-value := domain:get-field-value($id-field,response:body())
let $labels := 
    if(response:body()/*:uuid) then      
        ("Update","Save")
    else 
        ("New", "Create") 
return
    <div>
      <form id="form_{response:controller()}" name="form_{response:controller()}"  class="form-horizontal" method="post" action="/{response:controller()}/save.html">
        {if($domain-model//domain:element[@type = ("binary","file") or domain:ui/@type eq "fileupload"])
          then attribute enctype{"multipart/form-data"}
          else ()
         }                  
         <fieldset>
            <legend>New <?title?></legend>                 
             <div class="controls span12">
                {form:build-form($domain-model,$response)}
             </div>
             <div class="clearfix"></div>
             <div class="form-actions"> 
                 <button type="submit" class="btn btn-primary" href="#">{$labels[2]}
                 </button>
                 <button type="button" class="btn" href="#" onclick="window.location.href='/{response:controller()}/index.html';return false;">Cancel</button> 
              </div>
            </fieldset>
        </form>
       <script type="text/javascript"> 
        {form:context($response)}
        </script>
     </div>