declare default element namespace "http://www.w3.org/1999/xhtml";
<div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
        <div class="container">
            <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                <span class="icon-bar">&nbsp;</span>
                <span class="icon-bar">&nbsp;</span>
                <span class="icon-bar">&nbsp;</span>
            </a>
            <a class="brand" href="#">XQuerrail Demo</a>
            <div class="nav-collapse collapse">
                <ul class="nav">
                    <li class="active"><a href="#">Welcome</a></li>
                    <li><a href="/docs/">Documentation</a></li>
                    <li><a href="/api/">API</a></li>
                    <li><a href="http://github.com/garyvidal/xquerrail2" target="_new">GitHub</a></li>
                    <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Controllers <b class="caret">&nbsp;</b></a>
                        <ul class="dropdown-menu">
                            <?controller-list?>
                        </ul>
                    </li>
                </ul>
              
            </div><!--/.nav-collapse -->
        </div>
    </div>
</div>

