var indexGrid = null;
var codeMirrors = [];


function initToolbar(props) {
  var id = jQuery(indexGrid).jqGrid('getGridParam', 'selrow');
  if(props["new"] == true){
     jQuery("#toolbar").append("<a id='new-button' class='btn btn-primary'><b class='icon-plus icon-white'></b> New</a>");
     jQuery("#new-button").click(function() {newForm();});
  }
  if(props['edit'] == true) {
     jQuery("#toolbar").append("<a id='edit-button' class='btn btn-primary'><b class='icon-edit icon-white'></b> Edit</a>");
     jQuery("#edit-button").click(function() {editForm();});
  }
  if(props["delete"] == true) {
     jQuery("#toolbar").append("<a id='delete-button' class='btn btn-primary'><b class='icon-remove icon-white'></b> Delete</a>");
     jQuery("#delete-button").click(function() {deleteForm();});
  }
  if(props['show'] == true){
     jQuery("#toolbar").append("<a id='show-button' class='btn btn-primary'><b class='icon-eye-open icon-white'></b> Show</a>");
     jQuery("#show-button").click(function() {showForm();});
  }
  if(props['search'] == true) {
     jQuery("#toolbar").append("<a id='search-button' class='btn btn-primary'><b class='icon-filter icon-white'></b> Filter</a>");
     jQuery("#search-button").click(function() {jQuery(indexGrid).jqGrid('searchGrid',{multipleSearch:true});});     
  }
  if(props['export'] == true) {
     jQuery("#toolbar").append("<a id='export-button' class='btn btn-primary'><b class='icon-download icon-white'></b> Export</a>");
     jQuery("#export-button").click(function() {exportForm();});
  }  
  if(props['import'] == true) {
     jQuery("#toolbar").append("<a id='import-button' class='btn btn-primary'><b class='icon-upload icon-white'></b> Import</a>");
     jQuery("#import-button").click(function() {importForm();});
  } 
  //jQuery("#toolbar").buttonset();  
}
//new Form
function newForm() {
   window.location.href = "/" + context.controller + "/new.html";
}

function editForm() { 
   if(context.currentId != null) {
            window.location.href = "/" + context.controller + "/edit.html?" + context.modelId + "=" + context.currentId;
   } else if(context.currentId == null ){
     alert("Please select a record");
   }
}

function deleteForm() {
  
   if(context.currentId != null) {
      var c = confirm("Delete '" + context.currentLabel +"' ?");
      if(c) {
        window.location.href = "/" + context.controller + "/remove.html?" + context.modelId + "=" + context.currentId;
      }
   } else if(context.currentId == null ){
     alert("Please select a record");
   }
};

function showForm(){
  if(_id != null) {
   var url = "/" + context.controller + "/show.html?_partial=true&" + context.modelId + "=" + context.currentId;
   jQuery('#popup').html("<div class='loading'>...</div>");
   jQuery.get(url, function (data) {
         jQuery('#popup').html(data);
   });
   jQuery("#popup").dialog({ 
      width: 800, 
      height: 600, 
      autoOpen: true,
      resizable:false,
      modal:true,
      zIndex:999999,
      title:'Show ' + _id   
   }); 
  } else {
    alert("Please select a record");
  }  
}

// Sends the partial form back to UI
function importForm() {
 var url = "/" + context.controller + "/import.html?_partial=true";
 jQuery('#popup').html("<div class='loading'>...</div>");
  jQuery.get(url, function (data) {
        jQuery('#popup').html(data);
  });
  jQuery("#popup").dialog({ 
     width: 800, 
     height: 600, 
     autoOpen: true,
     resizable:false,
     modal:true,
     zIndex:999999,
     title:'Import Options'     
  });
}

//Popup Dialog Form
function exportForm() {
  var url = "/" + context.controller + "/export.html?_partial=true";
  jQuery('#popup').html("<div class='loading'>...</div>");
  jQuery.get(url, function (data) {
        jQuery('#popup').html(data);
  });
  jQuery("#popup").dialog({ 
     width: 840, 
     height: 500, 
     autoOpen: true ,
     modal:true ,
     title:'Export Options'     
  });
}
//Creates a partial form inside of ajax 
function editFormAjax(container) {

}

function newFormAjax(container) {

}
function deleteFormAjax(container) {

}

/*Grid Helper */
var gridHelper = window.gridHelper || {}
gridHelper = {
    "_this" : this,
    _context : {},
    context  : function(context) {this._context = context},
    init : function() { /*Globals*/
         jQuery.extend(jQuery.jgrid.defaults, {
             prmNames: { 
                 oper: "_oper", 
                 page: "page",
                 sidx: "sb", 
                 sord: "sort", 
                 page: "pg", 
                 rows: "rows", 
                 search:"search",
                 filters: "filter"
             }
         });
    },
    resizeGrid : function () {
        jQuery(indexGrid).setGridWidth(jQuery("#list-wrapper").innerWidth()) - 80;
        jQuery(indexGrid).setGridHeight(jQuery("#list-wrapper").innerHeight() - 80);
    },
    xmlListReaderSettings : function() {
        return  {
            root: 'list',
            row: context.modelName,
            id: context.modelIdSelector,
            page: 'list>currentpage',
            total: 'list>totalpages',
            records: 'list>totalrecords',
            repeatitems: false
        };
   },
   jsonListReaderSettings : function() {
       return {
            root: 'list',
            id: context.modelId,
            page: 'currentpage',
            total: 'totalpages',
            records: 'totalrecords',
            repeatitems: false
        };
    },
    initListGrid : function(gridId, gridParams) {
        indexGrid = gridId;
        jQuery(gridId).jqGrid(gridParams)
        .navGrid(gridId + '_pager',{edit: false, add: false, del: false, search: false, reload: true});
        
        jQuery ("table.ui-jqgrid-btable tr", jQuery(gridId)).css ("height", 28);
        jQuery ("ui-pg-table .ui-pg-selbox").css("height",24);
        jQuery(gridId).trigger("reloadGrid");   
        $(window).on("resize","", function(e) {
            gridHelper.resizeGrid();
        });    
    },
    initListGridAndPager : function(gridId, pagerId, gridParams) {
        indexGrid = gridId;
        jQuery(gridId).jqGrid(gridParams)
        .navGrid(pagerId,{edit: false, add: false, del: false, search: false, reload: false});
        jQuery ("table.ui-jqgrid-btable tr", jQuery(gridId)).css ("height", 22);
        jQuery(gridId).trigger("reloadGrid");   
        $(window).on("resize","", function(e) {
            gridHelper.resizeGrid();
        });
        gridHelper.resizeGrid();    
    },
    /*Grid Formatter for binary Output*/
    binaryFormatter : function (cellValue, options, rowObject) {
         return $(rowObject).find(options.colModel.name).attr("filename");
    },   
    /* Grid Formatter for array or repeater elements*/
    arrayFormatter : function(cellValue, options, rowObject) {
          var values = [];
          $(rowObject).find(options.colModel.name).each(function(i,e) {
             values.push($(e).text());
          });
          if(values.length == 0) {
          return "&nbsp;";
          } else { 
            return "(" + values.join("; ") + ")";
          }
   }
   /*gridHelper*/
}

/*
  Initializes any controls that are loaded using specific plugins
  To ensure all controls are rendered within the context then 
  make sure to call this after loading a form from a partial call
*/
function initControls() {
    $("input.binary").fileupload();
    $("input.time").timepicker();
    $("div.dateTime").datetimepicker({autoclose:true});
    $("input.date").datepicker({autoclose :true});
    $(".textarea").wysihtml5({
    	"font-styles": true, //Font styling, e.g. h1, h2, etc. Default true
    	"emphasis": true, //Italics, bold, etc. Default true
    	"lists": true, //(Un)ordered lists, e.g. Bullets, Numbers. Default true
    	"html": true, //Button which allows you to edit the generated HTML. Default false
    	"link": true, //Button to insert a link. Default true
    	"image": true, //Button to insert an image. Default true,
    	"color": false, //Button to change color of font  
        "parserRules" : wysihtml5ParserRules
        
    });
};

$(function() {
    /*Initialize Grids if present*/
    if(window.gridModel != undefined) {
        gridModel.xmlReader = gridHelper.xmlListReaderSettings();
        gridModel.jsonReader = gridHelper.jsonListReaderSettings();
        gridHelper.initListGrid("#" + context.controller + "_table",gridModel);
        gridHelper.resizeGrid();
    }
    if(window.toolbarMode != undefined) { 
        initToolbar(toolbarMode);
    }
    //Initialize any dynamic form controls
    initControls();
});            
