xquery version "1.0-ml";

import module namespace response = "http://www.xquerrail-framework.com/response"
at "/_framework/response.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:output "indent-untyped=yes";

declare variable $response as map:map external;
(
response:initialize($response),
<pre>{
    xdmp:quote(response:body()[1])
}</pre>
)
