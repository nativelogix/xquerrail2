xquery version "1.0-ml";
(:~
 : Base Edit Template used for rendering output
~:)
declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form     = "http://www.xquerrail-framework.com/helper/form-builder" at "/_framework/helpers/form-builder.xqy";
import module namespace response = "http://www.xquerrail-framework.com/response" at "/_framework/response.xqy";
import module namespace domain   = "http://www.xquerrail-framework.com/domain" at "/_framework/domain.xqy";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
let $domain-model := response:model()
let $id-field := fn:data(response:body()//*[fn:local-name(.) eq domain:get-model-identity-field-name($domain-model)])
let $form-mode := form:mode("edit") 
let $labels := ("Update","Cancel")
let $actions :=   
    <div class="btn-toolbar form-actions">
        <div class="btn-group">
             <button type="submit" class="btn btn-primary" href="#">
              <b class="icon-ok-sign icon-white"></b> Save
              </button>
              <button type="button" class="btn" onclick="return deleteForm('form_{response:controller()}','{response:controller()}_table');">
              <b class="icon-remove"></b>  Delete
              </button>
              <button type="button" class="btn" href="#" onclick="window.location.href='/{response:controller()}';">
              <b class="icon-hand-left"></b> Cancel</button>
        </div>
      </div>
return
<div>

  <div>
     <form id="form_{response:controller()}" name="form_{response:controller()}"  class="form-horizontal" method="post"
                 action="/{response:controller()}/save.html">
       {if($domain-model//domain:element[@type = ("binary","file") or domain:ui/@type eq "fileupload"])
         then attribute enctype{"multipart/form-data"}
         else ()
        }                     
             <fieldset>
               <legend>Edit <?title?></legend>
        
                {$actions}                
                <div class="controls span12">
                   {form:build-form($domain-model,$response)}
                </div>
                <div class="clearfix"></div>
                <div class="form-actions"> 
                    <button type="submit" class="btn btn-primary" href="#"><b class="icon-ok-sign icon-white"></b> Save</button> 
                </div>
               </fieldset>
           </form>
   </div>
   <script type="text/javascript"> 
    {form:context($response)}
    </script>
</div>
