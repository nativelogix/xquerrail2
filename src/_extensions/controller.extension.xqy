xquery version "1.0-ml";

(:~
 : Library provides the ability to create your own custom actions are accessible from all 
 : dynamic controllers.  To ensure your extension module is called you must add the following
 : entry to your _config/config.xml
 : 
 : <controller-extension  resource="/_extensions/controller.extension.xqy"/>
 :
 : The signature of your action(function) should be a 0 parameter function.
 
~:)
module namespace extension = "http://xquerrail.com/controller/extension";

import module namespace controller = "http://xquerrail.com/controller/base"
    at "/_framework/base/base-controller.xqy";
    
import module namespace request ="http://xquerrail.com/request"
    at "/_framework/request.xqy";
    
import module namespace response =  "http://xquerrail.com/response"
    at "/_framework/response.xqy";

import module namespace domain = "http://xquerrail.com/domain"
    at "/_framework/domain.xqy";
    
import module namespace model = "http://xquerrail.com/model/base"
    at "/_framework/base/base-model.xqy";
(:~
 : Here is a sample method that creates an instance of the controller model
~:)    
declare function extension:instance() {
  model:create(controller:model(),request:params())
};
(:~
 : Implementation of a custom function
~:)
declare function extension:my-custom-function() {
  <todo>Implement your custom function {request:param("name")}</todo>
};
(:Add:)