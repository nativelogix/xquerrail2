declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace response = 'http://xquerrail.com/response'
    at '/_framework/response.xqy';
declare variable $response external;
response:initialize($response),
<div class="well sidebar-nav">
   <h3><span class="icon-search"></span>API</h3>
   <ul class="nav nav-list">
    {for $doc in response:data("apilist")/*:apidoc
      order by (if(fn:data($doc/*:order) castable as xs:integer) then $doc/*:order else (),1)[1] cast as xs:integer
      return (
          if(fn:data($doc/*:header) ne "") 
          then  <li class="nav-header">{fn:data($doc/*:header)}</li>
          else (),          
          <li>
          {if(response:data("link") = $doc/*:link) then attribute class {"active"} else ()}
          <a href="/api/_/{$doc/*:link}">{fn:data($doc/*:title)}</a></li>
          )
     }   
   </ul>
</div>