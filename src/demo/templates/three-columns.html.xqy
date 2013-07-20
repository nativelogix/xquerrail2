declare default element namespace "http://www.w3.org/1999/xhtml";
<template>
    <!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
    <!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
    <!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
    <!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
        <?template name="head"?>
        <body>
            <!--[if lt IE 7]>
                <p class="chromeframe">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> or <a href="http://www.google.com/chromeframe/?redirect=true">activate Google Chrome Frame</a> to improve your experience.</p>
                <![endif]-->
            
            <!-- This code is taken from http://twitter.github.com/bootstrap/examples/hero.html -->
            <?template name="nav"?>
            <div class="container-fluid">
                <div class="row-fluid">
                    <div class="span3">
                        <?template name="sidebar"?>
                    </div>
                    <div class="span6">
                        <?view?>
                    </div>
                    <div class="span3">
                         <div class="sidebar-nav well">
                           <ul class="nav-list nav">
                             <li class="nav-header">Right Sidebar</li>  
                           </ul>
                           <?slot?>
                           <?endslot?>
                          </div>                 
                    </div>
                </div>
                <hr/>   
                <?template name="footer"?>
            </div> <!-- /container -->
            <?template name="scripts"?>
        </body>
    </html>
</template>/(comment()|node())