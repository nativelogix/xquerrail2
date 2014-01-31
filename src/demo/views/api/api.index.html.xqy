declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace response = 'http://xquerrail.com/response'
    at '/_framework/response.xqy';
declare variable $response external;
response:initialize($response),
<div class="row">
   <h3><span class="icon-search"></span>API</h3>
    {for $doc in response:data("apilist")/*:apidoc
      order by (if(fn:data($doc/*:order) castable as xs:integer) then $doc/*:order else (),1)[1] cast as xs:integer
      return (
          if(fn:data($doc/*:header) ne "") 
          then  (<div class="clearfix"/>,<h4>{fn:data($doc/*:header)}</h4>)
          else (),          
          <div class="span1">
          {if(response:data("link") = $doc/*:link) then attribute class {"active"} else ()}
          <a href="/api/_/{$doc/*:link}">{fn:data($doc/*:title)}</a>
            
          </div>,
          <div class="clearfix"/>
          )
       }
</div>