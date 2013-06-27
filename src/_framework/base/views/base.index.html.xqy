(:@GENERATED@:)
xquery version "1.0-ml";
declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace response = "http://www.xquerrail-framework.com/response" at "/_framework/response.xqy";

import module namespace domain = "http://www.xquerrail-framework.com/domain" at "/_framework/domain.xqy";

import module namespace js = "http://www.xquerrail-framework.com/helper/javascript" at "/_framework/helpers/javascript.xqy";
import module namespace form = "http://www.xquerrail-framework.com/helper/form-builder" at "/_framework/helpers/form-builder.xqy";


declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

declare variable $default-col-width := 40;
declare variable $default-resizable := fn:true();
declare variable $default-sortable  := fn:false();
declare variable $default-pagesize  := 100;

let $init := response:initialize($response)
let $domain-model := response:model()
let $model := $domain-model
let $model-editable := fn:not($domain-model/domain:navigation/@newable eq "false")
let $modelName := fn:data($domain-model/@name)
let $modelLabel := (fn:data($domain-model/@label),$modelName)[1]
let $gridCols := 
    for $item in $domain-model//(domain:element|domain:attribute)
    return form:field-grid-column($item)
let $editButtons := 
     js:o((
         js:p("search",($model/domain:navigation/@searchable,"true")[1]),
         js:p("new",($model/domain:navigation/@newable,"true")[1]),
         js:p("edit",($model/domain:navigation/@editable,"true")[1]),
         js:p("delete",($model/domain:navigation/@removable,"true")[1]),
         js:p("show",($model/domain:navigation/@showable,"false")[1]),
         js:p("import",($model/domain:navigation/@importable,"false")[1]),
         js:p("export",($model/domain:navigation/@exportable,"false")[1])
     ))
let $uuidMap :=  fn:string(<stmt>{{ name:'uuid', label:'UUID', index:'uuid',hidden:true }}</stmt>)
let $gridColsStr := fn:string-join(($uuidMap,$gridCols),",")
let $uuidKey := domain:get-field-id($domain-model/domain:element[@name = "uuid"])

(:Editable:)
let $editAction := 
    if($model-editable) 
    then <node>window.location.href = "/{response:controller()}/edit.html?" + context.modelId+  '=' + rowid;</node>/text()
    else <node>window.location.href = "/{response:controller()}/details.html?" + context.modelId +  '=' + rowid;</node>/text()
return
<div  class="container-fluid">
    <div class="row-fluid ui-layout-north">
        <div class="toolbar">
          <h3><?title?></h3>    
        </div>
    </div>
    <div class="row-fluid ui-layout-center">
       <div class="btn-toolbar">
          <div id="toolbar" class="btn-group">
          
          </div>
       </div>
    </div>
    <div class="row-fluid">
      <div id="list-wrapper" class="span12">
           <table id="{response:controller()}_table" class="index-grid"></table>
           <div id="{response:controller()}_table_pager"> </div>
        </div>           
        <div class="clearfix"> </div> 
    </div>
    <script type="text/javascript">
            {form:context($response)}
            var _id = null;
            var toolbarMode = {$editButtons};
            /*initialize your grid model*/
            var gridModel = {{
                url: '/{response:controller()}/list.xml',
                datatype: "xml",
                pager: '#{response:controller()}_table_pager',
                id : "{domain:get-model-identity-field-name(response:model())}",
                colModel: [{$gridColsStr}],
                loadonce:false,
                rowNum:100,
                pgbuttons: true,
                sortname: '{$domain-model/element[@identity eq 'true']/@name}',
                sortorder: 'desc',                
                //Grid Text
                emptyrecords: "No {$modelLabel}'s Found",
                loadtext: "Loading {$modelLabel}'s",
                gridview: true,
                altRows : true,
                pgbuttons:true,
                viewrecords :true,
                navigator:true,
                sortable:true,
                rownumbers:true,
                rowList: [20,50,100,200],
                width: '500',
                height: '500',
                multiselect: false,
                onSelectRow   : function(rowid,e) {{
                    var gsr = jQuery(this).jqGrid('getGridParam','selrow'); 
    			    if(gsr){{ 
    				   var rowData = jQuery(this).getRowData(gsr);
                       context.currentId = rowid;
                       context.currentLabel = rowData[context.modelKeyLabel];
                       return 
                          true;
                    }}
                }},
                ondblClickRow : function(rowid) {{
                    {$editAction}
                }}
                
            }};
           </script>
</div>