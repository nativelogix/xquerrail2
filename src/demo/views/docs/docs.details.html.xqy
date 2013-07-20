
<div xmlns="http://www.w3.org/1999/xhtml" class="span8">
    <span class="breadcrumb span12">/ <a href="/docs/">Documentation</a> / <b><?echo fn:string(response:body()/*:document/*:title)?></b>&nbsp;
        <span class="pull-right">
            <span class="icon-edit"></span>
            <?echo <a href="/docs/edit.html?uuid={response:body()/*:document/*:uuid}"> Edit </a>?>
        </span>
    </span>
    <div class="clearfix"/>
    <h3><?echo fn:data(response:body()/*:document/*:title)?></h3>
    <p></p>
    <?echo xdmp:unquote("<div xmlns='http://www.w3.org/1999/xhtml'>" || fn:data(response:body()/*:document/*:body || "</div>"),"","repair-full") ?>
</div>