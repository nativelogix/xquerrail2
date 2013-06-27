var indexGrid = null;
var codeMirrors = [];

function xmlListReaderSettings() {
    return  {
        root: 'list',
        row: context.modelName,
        id: context.modelIdSelector,
        page: 'list>currentpage',
        total: 'list>totalpages',
        records: 'list>totalrecords',
        repeatitems: false
    };
}

function jsonListReaderSettings() {
   return {
        root: 'list',
        id: context.modelId,
        page: 'currentpage',
        total: 'totalpages',
        records: 'totalrecords',
        repeatitems: false
    };
}


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

// Sends the partial form back to UI
function editForm() {
    window.location.href = "/" + context.controller + "/edit.html?" + context.modelId + "=" + context.currentId;
}

function deleteForm() {
  
   if(context.currentId != null) {
      var c = confirm("Delete '" + context.currentLabel +"' ?");
      if(c) {
        window.location.href = "/" + context.controller + "/remove.html?" + context.modelId + "=" + context.currentId;
      }
   } else if(_id == null ){
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
function resizeGrid() {
    jQuery(indexGrid).setGridWidth(jQuery("#list-wrapper").innerWidth()) - 80;
    jQuery(indexGrid).setGridHeight(jQuery("#list-wrapper").innerHeight() - 80);
}
function resizeLayout() {
  outerLayout.resizeAll();
  resizeGrid();
}

function initListGrid(gridId, gridParams) {
    indexGrid = gridId;
    jQuery(gridId).jqGrid(gridParams)
    .navGrid(gridId + '_pager',{edit: false, add: false, del: false, search: false, reload: true});
    /*.navButtonAdd(gridId + "_pager",{
       title: "Find",
       caption:"Find", 
       buttonicon: "ui-icon-search",    
       onClickButton:function() {
          jQuery(gridId).jqGrid('searchGrid',{multipleSearch:true});
    }
    })
    .navButtonAdd(gridId + "_pager",{
       title: "Columns",
       caption:"Columns", 
       buttonicon: "ui-icon-calc",    
       onClickButton:function() {
          jQuery(gridId).columnChooser({          
          });
    }
    });*/
    jQuery ("table.ui-jqgrid-btable tr", jQuery(gridId)).css ("height", 28);
    jQuery ("ui-pg-table .ui-pg-selbox").css("height",24);
    jQuery(gridId).trigger("reloadGrid");   
    $(window).on("resize","", function(e) {
        resizeGrid();
    });
    resizeGrid();    
}

function initListGridAndPager(gridId, pagerId, gridParams) {
    indexGrid = gridId;
    jQuery(gridId).jqGrid(gridParams)
    .navGrid(pagerId,{edit: false, add: false, del: false, search: false, reload: false});
   /* .navButtonAdd(pagerId,{
       title: "Search",
       caption:"", 
       buttonicon: "ui-icon-search",    
       onClickButton:function() {
          jQuery(gridId).jqGrid('searchGrid',{multipleSearch:true});
    }
    })
    .navButtonAdd(pagerId,{
       title: "Columns",
       caption:"", 
       buttonicon: "ui-icon-calc",    
       onClickButton:function() {
          jQuery(gridId).columnChooser({          
          });
    }
    });*/
    jQuery ("table.ui-jqgrid-btable tr", jQuery(gridId)).css ("height", 22);
    
    jQuery(gridId).trigger("reloadGrid");   
    $(window).on("resize","", function(e) {
        resizeGrid();
    });
    resizeGrid();    
}

function initLayout() {
   if(jQuery("#popup") != null) {
     jQuery(body).append("<div id='popup'></div>");
   }
}

/*Globals*/
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

function arrayFormatter(cellValue, options, rowObject) {
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

function binaryFormatter(cellValue, options, rowObject) {
    //return $(rowObject).find(options.colModel.name)[0].attributes["filename"].textContent;
    return $(rowObject).find(options.colModel.name).attr("filename");
}
$(function() {
    /*Initialize Grids if present*/
    if(window.gridModel != undefined) {
        gridModel.xmlReader = xmlListReaderSettings();
        gridModel.jsonReader = jsonListReaderSettings();
        initListGrid("#" + context.controller + "_table",gridModel);
    }
    if(window.toolbarMode != undefined) { 
        initToolbar(toolbarMode);
    }
    $("input.binary").fileupload();
    $("input.time").timepicker();
    $("div.dateTime").datetimepicker({autoclose:true});
    $("input.date").datepicker({autoclose :true});
});            
