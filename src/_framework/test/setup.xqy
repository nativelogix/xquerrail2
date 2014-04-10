xquery version "1.0-ml";
module namespace setup = "http://xquerrail.com/test/setup";

import module namespace domain  = "http://xquerrail.com/domain"      at "/_framework/domain.xqy";
import module namespace model   = "http://xquerrail.com/model/base"  at "/_framework/base/base-model.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin"  at "/MarkLogic/admin.xqy";

declare %private variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);

declare variable $PREFIX-TEST-URI := "/test/";

declare %private function bootstrap-model($model as element(domain:model)
) as empty-sequence() {
  try {
    let $model-name := $model/@name
    let $identity-field := domain:get-model-identity-field($model)
    let $identity-type := "string"
    let $identity-name := $identity-field/@name
    let $namespace := domain:get-field-namespace($identity-field)
    let $collation := domain:get-field-collation($identity-field)
    let $config := admin:get-configuration()
    let $database-id := xdmp:database()
    let $spec :=
    typeswitch($identity-field)
      case element(domain:element) return
        admin:database-add-range-element-index(
            $config,
            $database-id,
            admin:database-range-element-index(
              $identity-type,
              $namespace,
              $identity-name,
              $collation,
              fn:false()
            )
          )
      case element(domain:attribute) return
        admin:database-add-range-element-attribute-index(
            $config,
            $database-id,
            admin:database-range-element-attribute-index(
              $identity-type,
              $namespace,
              $model-name,
              (),
              $identity-name,
              $collation,
              fn:false()
            )
          )
    default return fn:error(xs:QName("UNSUPPORTED-IDENTITY-FIELD"), "Unsupported indentity field [" || $identity-name || "]")
    
    return
      admin:save-configuration($spec)
	} catch * {
    if (fn:starts-with($err:description, "ADMIN-DUPLICATECONFIGITEM")) then
      ()
    else
      xdmp:log("bootstrap-model - Error description [" || $err:description || "]", "warning")
	}
};

declare function setup($models as element(domain:model)?) as empty-sequence()
{
    xdmp:invoke-function(
      function() {
        for $model in $models
          return bootstrap-model($model)
        , xdmp:commit() 
      },
      <options xmlns="xdmp:eval">
        <transaction-mode>update</transaction-mode>
      </options>
    )
};

declare function teardown($models as element(domain:model)?) as empty-sequence()
{
  ()
(:  xdmp:invoke-function(
    function() {
      xdmp:collection-delete($collection)
      , xdmp:commit() 
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
    </options>
  )
:)};
