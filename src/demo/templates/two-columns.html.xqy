declare default element namespace "http://www.w3.org/1999/xhtml";
<template>
    <!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
    <!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
    <!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
    <!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
        <?template name="head"?>
        <body>
            <?template name="nav"?>
            <div class="container-fluid">
                <div class="row">
                    <div class="offset1 span2">
                        <?slot name="sidebar"?>
                          <?template name="sidebar"?>
                        <?endslot?>
                    </div>
                    <div class="span10">
                        <?view?>
                    </div>
                </div>
                <hr/>   
                <?template name="footer"?>
            </div> <!-- /container -->
            <?template name="scripts"?>
    </body>
    </html>
</template>/node()