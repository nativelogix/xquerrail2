xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/demo/model/apidoc";

import module namespace domain = "http://xquerrail.com/domain" at "/_framework/domain.xqy";
import module namespace xqdocs = "http://github.com/xquery/xquerydoc" at "/_framework/lib/xqdocs/xquery/ml-xquerydoc.xq";
import module namespace base  = "http://xquerrail.com/model/base" at "/_framework/base/base-model.xqy";

declare namespace dir = "http://marklogic.com/xdmp/directory";
declare namespace xqd = "http://www.xqdoc.org/1.0";

declare option xdmp:mapping "false";

declare function model:filesystem-filter($path as xs:string,$filter as xs:string) {
  model:filesystem-filter($path,$filter,"*")
};
(:~
 : Gets a list of files from a filesystem based on root path.
 : @param $path - Filesystem path
 : @param $filter - Filter the files by type as a regex.
 : @param $exclude - includes only the files that do not match a pattern.
 : @return - List of <file name="" path=""/>. The path is the full path of the file.
 :)
declare function model:filesystem-filter($path as xs:string,$filter as xs:string,$exclude as xs:string) {
  let $entries := xdmp:filesystem-directory($path)
  return
    for $entry in $entries/dir:entry[(fn:matches(dir:filename,$filter) and fn:not(fn:matches(dir:pathname,$exclude))) or dir:type = "directory"]
    return
      switch($entry/dir:type)
        case "file" return <file name="{$entry/dir:filename}" path="{$entry/dir:pathname}"/>
        case "directory" return model:filesystem-filter($entry/dir:pathname,$filter,$exclude)
        default return ()
};

(:Generated the documentation from :)
declare function model:generate-xqdocs-from-filesystem(
	$fs-path as xs:string,
	$relpath as xs:string
)  {
	let $module-root := xdmp:modules-root()
	let $root := $fs-path
	let $frameroot := $root || $relpath
	let $files := model:filesystem-filter($frameroot,"\.(xqy|xsl)$","/(templates|views|lib)/")
	let $generate := 
		for $file at $pos in $files
		return xdmp:spawn-function(function() {
			let $fname := $file/@name
			let $mod-text := fn:string(xdmp:binary-decode(xdmp:external-binary($file/@path),"utf8"))
			let $xqdoc := try { xqdocs:parse($mod-text,"")} catch($ex){<xqdocs:error/>}
			let $folder := $file/@path/fn:tokenize(.,"/")[fn:last() - 1] 
			let $location := fn:substring-after($file/@path,$module-root)
			let $namespace := $xqdoc//xqd:module/xqd:uri
			let $moduleType := $xqdoc//xqd:module/@type
			let $params := map:new((
			  map:entry("link",$fname),
			  map:entry("header",($folder,"Core")[1]),
			  map:entry("order",$pos),
			  map:entry("title",$fname),
			  map:entry("location",$location),
			  map:entry("namespace",$namespace),
			  map:entry("moduleType",$moduleType),
			  map:entry("xqdoc",$xqdoc)
			))
			return (
  			base:create(domain:get-model("demo","apidoc"),$params)[1],
  			xdmp:commit()
  		
		)},
	  <options xmlns="xdmp:eval">
	  <transaction-mode>update</transaction-mode>
    </options> )
		
	return ()
};
declare function  model:generate-framework-xqdocs() {
  generate-xqdocs-from-filesystem(xdmp:modules-root(),"_framework")
};