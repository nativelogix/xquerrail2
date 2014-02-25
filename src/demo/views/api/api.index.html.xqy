declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace response = 'http://xquerrail.com/response'
    at '/_framework/response.xqy';
declare variable $response external;
declare option xdmp:output "indent-untyped=yes";
response:initialize($response),
<div id="api-body" class="row">
  <h2>XQuerrail API Documentation</h2>
<table class="table striped">
  <thead>
   <tr>
     <th>Module Type</th>
     <th>Module Name</th>
     <th>Namespace</th>
     <th>Location</th>
   </tr>
  </thead>
{
 let $group := ""
     let $apidocs := for $doc in response:body()//*:apidoc order by $doc/*:header,$doc/*:title return $doc
     return
       if($apidocs) then
        for $doc in $apidocs
        let $application := $doc/*:application
        let $header := function() {
            let $value := $doc/*:header
            let $size := fn:string-length($value)
            return
              fn:string-join(
                for $s in (1 to $size)
                let $string :=  fn:substring($value,$s,1)
                return 
                  if($s = 1) then fn:upper-case($string) else $string,
              "")
       }()
        return ( 
            if($group = $header) then () else 
            <tr>
              <td colspan="4"><h5>{fn:data($header)}</h5></td></tr>,
              xdmp:set($group,$header),
            <tr>
            {if(response:data("link") = $doc/*:link) then attribute class {"active","api-link"} else attribute class {"api-link"}}
            <td>{fn:data($doc/*:moduleType)}</td>
            <td><a href="/api/_/{$doc/*:link}">{fn:data($doc/*:title)}</a></td>
            <td>{fn:data($doc/*:namespace)}</td>
            <td>{fn:data($doc/*:location)}</td>
            </tr>
            )
        else  
            <div class="alert">
              <button type="button" class="close" data-dismiss="alert">&times;</button>
              <strong>Document not available.</strong> Would you like to generate now?
              <a id="generate-docs" href="generate.html">Generate</a>
            </div>
}</table></div>