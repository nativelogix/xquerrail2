 function invokeTests() {
        var testCount = 0;
        $("h4.test").each(function(i,e) {
            var checkRun = $(this).find("input[type=checkbox]").prop("checked");
            testCount += $(this).find("input[type=checkbox]").prop("checked") == true ? 1:0;
        });
        if(testCount == 0) {
            alert("No Tests Selected");
            return;
        }
        $("h4.test").each(function(i,e) {
           var checkRun = $(this).find("input[type=checkbox]").prop("checked");
           if(checkRun) {
               $(this).append('<div id="spinner" class="spinner">');
               setTimeout(function() {
                $("#spinner").remove();
               },2000);
           }
        });
}
     
/*OnReady*/
$(function(){
     $("h3.module input[type=checkbox]").click(function(){
        var checked = this.checked;
        $(this).parent().next().find("input[type=checkbox]").each(
        function(i,e) {
          if(checked){
            $(e).attr("checked",checked);
          } else {
            $(e).removeAttr("checked");
            $(e).val('');
          }
         });
     });
     //global check
     $("#check-all").click(function() {
          var checked = this.checked;
          $(document).find("input[type=checkbox]").each(
             function(i,e) {
                   if(checked){
                     $(e).attr("checked",checked);
                   } else {
                     $(e).removeAttr("checked");
                     $(e).val('');
                   }
           });
     });
     
     //Module toggler
      $("h3.module div.toggler").click(function(){
        $(this).toggleClass('open');
        $(this).parent().next().toggle('wipe');
     });
     //All toggler open
      $("div#toggle-open-all").click(function(){
        $("h3.module div.toggler").addClass("open");
        $("h3.module").each(function(i,e) {
          $(this).next().show('wipe');           
        });
     });
     //All toggler close
      $("div#toggle-close-all").click(function(){
       $("h3.module div.toggler").removeClass("open");
        $("h3.module").each(function(i,e) {
          $(this).next().hide('wipe');           
        });
     });
     //Execute Test Runner
     $("#execute-tests").click(function(){
         invokeTests();
      });
      
      /*End Initialize*/
  });