<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
                version="2.0"
                exclude-result-prefixes="xray xdmp">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="test-dir"/>
  <xsl:param name="module-pattern"/>
  <xsl:param name="test-pattern"/>

  <xsl:template match="xray:tests">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <title>xray</title>
        <link rel="icon" type="image/png" href="favicon.png" />
        <script type="text/javascript" src="jquery.js"/>
        <xsl:call-template name="css"/>
        <script type="text/javascript" src="xray.js"></script>
      </head>
      <body>
        <xsl:call-template name="header"/>
        <form name="tests">
            <xsl:apply-templates/>
        </form>
        <xsl:call-template name="summary"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="xray:module">
    <h3 class="module"><input type="checkbox"/>
      <label><abbr ><xsl:attribute name="title" select="@path"/></abbr>
      <xsl:value-of select="@name"/></label>
      <div class="toggler open"></div>
    </h3>
    
    <div class="module">  
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="xray:test">
    <h4 class="test {@result}">
       <input id="{@id}" class="test" type="checkbox"/>
      <span class="test"><xsl:value-of select="@name"/></span>
      <span class="status"></span>

    </h4>
    <div class="results">
        <xsl:call-template name="result"/>
    </div>
  </xsl:template>

  <xsl:template name="result">
    <xsl:if test="@result = 'failed'">
      <pre><xsl:value-of select="xdmp:quote(.)"/></pre>
    </xsl:if>
  </xsl:template>

  <xsl:template name="header">
      <h1><a href="http://github.com/robwhitby/xray">xray</a></h1>
      <h2 class="all">
         <input id="check-all" type="checkbox" checked="checked"/>TestSuites:
         <button id="execute-tests" type='button'>Run</button>
         <div id="toggle-open-all" class="toggler"/>
         <div id="toggle-close-all" class="toggler open"/>
       </h2>
  </xsl:template>

  <xsl:template match="error:error">
    <pre><xsl:value-of select="xdmp:quote(.)"/></pre>
  </xsl:template>

  <xsl:template name="summary">
    <p id="summary">
      <xsl:choose>
        <xsl:when test="xray:module[xray:test|error:error]">
          <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="xray:module[xray:test/@result='failed' or error:error]">failed</xsl:when>
                <xsl:otherwise>passed</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="'Finished: Total', count(xray:module/xray:test)" />
          <xsl:value-of select="', Failed', count(xray:module/xray:test[@result='failed'])" />
          <xsl:value-of select="', Ignored', count(xray:module/xray:test[@result='ignored'])" />
          <xsl:value-of select="', Errors', count(xray:module/error:error)" />
          <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" />
        </xsl:when>
        <xsl:otherwise>
          No matching tests found
        </xsl:otherwise>
      </xsl:choose>
    </p>
    <p>
      <xsl:variable name="qs" select="concat('?dir=', $test-dir, 
                                            '&amp;modules=', encode-for-uri($module-pattern), 
                                            '&amp;tests=', encode-for-uri($test-pattern), 
                                            '&amp;format=')"/>
      View as <a href="{$qs}xml">xml</a>&#160;<a href="{$qs}text">text</a>
    </p>
  </xsl:template>

  <xsl:template name="css">
    <style type="text/css">
      body { margin: 0 10px; font-size:.8em; }
      body, input, button { font-family: "Courier New",Sans-serif; }
      h1 { margin: 0 0 30px 0; }
      div.module h3, div.module h2   {margin-bottom:0px;webkit-border-top-right-radius: 8px;-webkit-border-top-left-radius: 8px;-moz-border-radius-topright: 8px;-moz-border-radius-topleft: 8px;border-top-right-radius: 8px;border-top-left-radius: 8px;}
      h1 a:link, h1 a:visited, h1 a:hover, h1 a:active { padding: 10px 10px; text-decoration:none; color: #fff; background-color: #000; border: 1px solid #000; }
      h1 a:hover { color: #000; background-color: #fff; }
      h2, h3, h4, pre { margin: 0; padding: 5px 10px; font-weight: normal; }
      h3 { background-color: #eee; }
      h2 {background-color:#333;color:#fff;}
      label { padding-left: 10px; }
      abbr, .abbr { border-bottom: 1px dotted #ccc; }
      fform { position: absolute; top: 10px; right: 10px; }
      #summary { font-weight: bold; }
      .module { border-left: 1px solid #ccc;border-right: 1px solid #ccc; border-bottom: 1px solid #ccc;margin: 0 10px;}
      .failed { color: red; }
      .ignored { color: orange; }
      .passed { color: green; }
      .spinner {display:inline-block;width:16px;height:16px; background-image: url('spinner.gif') }
      .toggler {display:block;float:right;height:16px;width:16px}
      .toggler.open { background-image : url('toggle.png')}
      .toggler{ background-image : url('toggle-expand.png')}
    </style>
  </xsl:template>

</xsl:stylesheet>
