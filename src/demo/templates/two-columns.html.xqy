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
                <div class="row-fluid">
                    <div class="span3 well">
                        <?slot name="sidebar"?>
                          <?template name="sidebar"?>
                        <?endslot?>
                    </div>
                    <div class="span9">
                        <?view?>
                    </div>
                </div>
                <div class="row-fluid">
                <hr/>   
                <?template name="footer"?>
                </div>
            </div> <!-- /container -->
            <?template name="scripts"?>
    </body>
    </html>
</template>/node()