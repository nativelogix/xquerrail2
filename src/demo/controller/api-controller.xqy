xquery version "1.0-ml";
(:~
 : API Application Controller
 : @author garyvidal@hotmail.com
~:)
module namespace controller = "http://www.xquerrail-framework.com/demo/controller/api";

import module namespace request = "http://www.xquerrail-framework.com/request"
    at "/_framework/request.xqy";
    
import module namespace response = "http://www.xquerrail-framework.com/response"
    at "/_framework/response.xqy";

import module namespace domain = "http://www.xquerrail-framework.com/domain"
    at "/_framework/domain.xqy";

import module namespace base = "http://www.xquerrail-framework.com/model/base"
    at "/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function controller:model() {
  domain:get-model("apidoc")
};
declare function controller:index() {
   response:set-view("index"),
   response:set-template("two-columns"),
   response:set-data("apilist",base:list(domain:get-model("apidoc"),request:params())),
   response:set-slot("sidebar",<?template name="api-nav"?>),
   response:flush()
};

declare function details() {
   response:set-template("two-columns"),
   response:set-slot("sidebar",<?template name="api-nav"?>),
   response:add-data("link",request:param("link")),
   response:add-data("apilist",base:list(domain:get-model("apidoc"),request:params())),
   response:set-body(base:find(domain:get-model("apidoc"),request:params())),
   response:flush()
};

declare function save() {
  let $save := base:create-or-update(model(),request:params())
  return
     xdmp:redirect-response("/api/_/" || $save/*:link)
};