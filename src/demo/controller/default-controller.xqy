xquery version "1.0-ml";
(:~
 : Default Application Controller
 : @author garyvidal@hotmail.com
 :)
module namespace controller = "http://xquerrail.com/demo/controller/default";

import module namespace request = "http://xquerrail.com/request"
    at "/_framework/request.xqy";
    
import module namespace response = "http://xquerrail.com/response"
    at "/_framework/response.xqy";

declare function controller:initialize($request)
{
   request:initialize($request),
   response:initialize(map:map(),$request)
};

declare function controller:main()
{
  controller:index()
};

declare function controller:index()
{(
    response:set-controller("default"),
    response:set-action("index"),
    response:set-template("main"),
    response:set-view("index"),
    
    response:set-title(fn:concat("Welcome: ",xdmp:get-current-user())),
    response:add-httpmeta("cache-control","public"),
    response:flush()
)};

declare function controller:login()
{
 let $username   := request:param("username")[1] 
 let $password   := request:param("password")[1]
 let $returnUrl  := request:param("returnUrl")
 return 
    if($username ne "" or $password ne "") then     
       let $is-logged-in := xdmp:login($username,$password)
       return
       if($is-logged-in) then (
          if($returnUrl ne "" and $returnUrl) then 
            response:redirect($returnUrl)
          else 
           response:redirect("default","index"),
           response:flush()
        ) 
        else 
        ( 
           response:set-flash("login","Invalid Username or Password"),
           response:set-controller("default"),
           response:set-template("main"),
           response:set-view("login"),
           response:set-title("Login"),
           response:response()
     )
     else (
       if(request:param("login") = "login") 
       then response:set-flash("login","Please enter username and password")
       else (),
       response:set-controller("default"),
       response:set-template("main"),
       response:set-view("login"),
       response:set-title("Login"),
       response:response()
    )
};

declare function controller:logout()
{(
    xdmp:logout(),
    response:redirect("/"),
    response:flush()
)};
declare function controller:three-columns() {
   response:set-view("index"),
   response:set-template("three-columns"),
   response:flush()
};

