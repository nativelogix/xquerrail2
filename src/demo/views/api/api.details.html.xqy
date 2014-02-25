<div xmlns="http://www.w3.org/1999/xhtml" class="span11">
  <div class="row-fluid">
    <span class="breadcrumb span12">/ <a href="/api/"> API </a> / <b><?echo fn:string(response:body()/*:apidoc/*:title)?></b>&nbsp;
        <span class="pull-right">
            <span class="icon-edit"></span>
            <?echo <a href="/api/edit.html?uuid={response:body()/*:apidoc/*:uuid}"> Edit </a>?>
        </span>
    </span>
    <div class="span12">
        <h3><?echo fn:data(response:body()/*:apidoc/*:title)?></h3>
        <?xsl source="response:body()/*:apidoc/*:xqdoc/node()" xsl="/demo/resources/xsl/html-module.xsl" params="response:data('params')" ?>
    </div>
    <link rel="stylesheet" type="text/css" href="/resources/js/vendor/prettify/prettify.css">&#160;</link>
    <script type="text/javascript" src="/resources/js/vendor/prettify/prettify.js">//</script>
    <script type="text/javascript" src="/resources/js/vendor/prettify/lang-xq.js">//</script>
  </div>
</div>