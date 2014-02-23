$(function() {
   $(".api-link a").click(function(e){
   	 e.preventDefault();
     var link = $(this).attr("href");
     $(".api-link.active").removeClass("active");
     $(this).parent().addClass("active");
     $("#api-body").empty().load(link + "?_partial=true");

   });

   $("#generate-docs").click(function(e){
   	  e.preventDefault();
   	  $("#api-body").empty().load($(this).attr("href"));
      $(this).parent(".alert").remove();

   });
});