xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";

declare option xdmp:mapping "false";

declare %test:case function test-set-cookie-with-value() as item()*
{
  let $cookie := response:set-cookie("cookie1", "value1", (), (), (), ())
  return 
  (
    assert:not-empty($cookie),
    assert:true(fn:starts-with($cookie, "cookie1=value1"), "Must start with cookie value"),
    assert:true(fn:contains($cookie, "HttpOnly")),
    assert:false(fn:contains($cookie, "Max-Age")),
    assert:false(fn:contains($cookie, "Secure")),
    assert:false(fn:contains($cookie, "Domain")),
    assert:false(fn:contains($cookie, "Path"))
  )
};

declare %test:case function test-set-cookie-no-value() as item()*
{
  let $cookie := response:set-cookie("cookie1", "", xs:dayTimeDuration('PT0S'), (), (), ())
  return 
  (
    assert:not-empty($cookie),
    assert:true(fn:starts-with($cookie, "cookie1="), "Must start with cookie1="),
    assert:true(fn:contains($cookie, "HttpOnly")),
    assert:true(fn:contains($cookie, "Max-Age")),
    assert:false(fn:contains($cookie, "Secure")),
    assert:false(fn:contains($cookie, "Domain")),
    assert:false(fn:contains($cookie, "Path"))
  )
};

declare %test:case function test-set-cookie-with-secure() as item()*
{
  let $cookie := response:set-cookie("cookie1", "value1", (), fn:true(), (), ())
  return 
  (
    assert:not-empty($cookie),
    assert:true(fn:starts-with($cookie, "cookie1=value1"), "Must start with cookie value"),
    assert:true(fn:contains($cookie, "HttpOnly")),
    assert:false(fn:contains($cookie, "Max-Age")),
    assert:true(fn:contains($cookie, "Secure")),
    assert:false(fn:contains($cookie, "Domain")),
    assert:false(fn:contains($cookie, "Path"))
  )
};

declare %test:case function test-set-cookie-with-path() as item()*
{
  let $cookie := response:set-cookie("cookie1", "value1", (), (), (), "/")
  return 
  (
    assert:not-empty($cookie),
    assert:true(fn:starts-with($cookie, "cookie1=value1"), "Must start with cookie value"),
    assert:true(fn:contains($cookie, "HttpOnly")),
    assert:false(fn:contains($cookie, "Max-Age")),
    assert:false(fn:contains($cookie, "Secure")),
    assert:false(fn:contains($cookie, "Domain")),
    assert:true(fn:contains($cookie, "Path=/"))
  )
};

declare %test:case function test-set-cookie-with-domain() as item()*
{
  let $cookie := response:set-cookie("cookie1", "value1", (), (), "marklogic.com", ())
  return 
  (
    assert:not-empty($cookie),
    assert:true(fn:starts-with($cookie, "cookie1=value1"), "Must start with cookie value"),
    assert:true(fn:contains($cookie, "HttpOnly")),
    assert:false(fn:contains($cookie, "Max-Age")),
    assert:false(fn:contains($cookie, "Secure")),
    assert:true(fn:contains($cookie, "Domain=marklogic.com")),
    assert:false(fn:contains($cookie, "Path"))
  )
};
