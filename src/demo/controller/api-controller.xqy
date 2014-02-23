xquery version "1.0-ml";
(:~
 : API Application Controller
 : @author garyvidal@hotmail.com
 :)
module namespace controller = "http://xquerrail.com/demo/controller/api";

import module namespace request = "http://xquerrail.com/request"
    at "/_framework/request.xqy";
    
import module namespace response = "http://xquerrail.com/response"
    at "/_framework/response.xqy";

import module namespace domain = "http://xquerrail.com/domain"
    at "/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base"
    at "/_framework/base/base-model.xqy";
import module namespace api-model = "http://xquerrail.com/demo/model/apidoc"
    at "/demo/models/apidoc-model.xqy";

declare option xdmp:mapping "false";

declare function controller:model() {
  domain:get-model("apidoc")
};

declare function controller:generate() {(
   xdmp:directory-delete("/docs/"),
   api-model:generate-framework-xqdocs(),
   <generated>Docs are being generated</generated>
   )
};

declare function controller:index() {
  let $list := base:list(domain:get-model("demo","apidoc"),request:params())
  return (
   response:set-template("two-columns"),
   response:set-body($list),
   response:set-slot("sidebar",<?template name="api-nav"?>),
   response:flush()
)};

declare function details() {
   let $api := base:find(domain:get-model("apidoc"),request:params())
   return (
     response:set-template("two-columns"),
     response:set-slot("sidebar",<?template name="api-nav"?>),
     response:add-data("link",request:param("link")),
     response:add-data("apilist", base:list(domain:get-model("apidoc"),request:params())),
     response:add-data("params",  map:entry("location", $api//*:location)),
     response:set-body($api),
     response:flush()
   )
};

declare function save() {
  let $save := base:create-or-update(model(),request:params())
  return
     xdmp:redirect-response("/api/_/" || $save/*:link)
};