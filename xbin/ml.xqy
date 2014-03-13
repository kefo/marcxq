xquery version "1.0-ml";

(:
:   Module Name: MARC/XML BIB 2 BIBFRAME RDF using MarkLogic
:
:   Module Version: 1.0
:
:   Date: 2012 December 03
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: xdmp (MarkLogic)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Transforms MARC/XML Bibliographic records
:       to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:       N-triples, or JSON.
:
:)

(:~
:   Transforms MARC/XML Bibliographic records
:   to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:   N-triples, or JSON.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since December 03, 2012
:   @version 1.0
:)

(: IMPORTED MODULES :)

import module namespace marcxml2marcjson = "http://3windmills.com/marcxq/modules/marcxml2marcjson#" at "../modules/module.MARCXML-2-MARCJSON.xqy";
import module namespace marcjson2marcxml = "http://3windmills.com/marcxq/modules/marcjson2marcxml#" at "../modules/module.MARCJSON-2-MARCXML.xqy";
import module namespace marc27092xmljson = "http://3windmills.com/marcxq/modules/marc27092xmljson#" at "../modules/module.ISO2709-2-MARC.xqy";

import module namespace xqilla = "http://xqilla.sourceforge.net/Functions" at "../modules/module.JSON-2-SnelsonXML.xqy";


(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";

declare namespace   marcxml             =   "http://www.loc.gov/MARC21/slim";
declare namespace   map                 =   "http://marklogic.com/xdmp/map";


declare option xdmp:output "indent-untyped=yes" ; 

(:~
:   This variable is for the location of the source MARC.
:)
declare variable $s as xs:string := xdmp:get-request-field("s","");

(:~
:   Set the input serialization. Expected values are: xml (default), json
:)
declare variable $i as xs:string := xdmp:get-request-field("i","xml");

(:~
:   Set the output serialization. Expected values are: xml (default), json
:)
declare variable $o as xs:string := xdmp:get-request-field("o","xml");

let $sname := 
    if ( fn:not(fn:matches($s, "^(http|ftp)")) ) then
        fn:concat("file://", $s)
    else
        $s

let $source := 
    if ($i eq "json" or $i eq "iso2709") then
        xdmp:document-get(
            $s, 
            <options xmlns="xdmp:document-get">
                <format>text</format>
            </options>
        )
    else 
        xdmp:document-get(
            $s, 
            <options xmlns="xdmp:document-get">
                <format>xml</format>
            </options>
        )

let $source := 
    if ($i eq "json") then
        let $s := xdmp:from-json($source)
        return 
            for $map in $s
            let $m := 
                element map:map {
                    element leader { map:get($map, "leader") },
                    element fields { map:get($map, "fields") }
                }
            return $m
        (: xqilla:parse-json($source) :)
    else if ($i eq "iso2709") then
        $source
        
    else
        $source//marcxml:record

let $output := 
    if ($i eq "iso2709") then
        marc27092xmljson:marc27092xmljson($source, $o)
    else if ($o eq "json") then
        if (count($source) eq 1) then
            marcxml2marcjson:marcxml2marcjson($source)
        else
            let $objects := 
                for $r in $source
                return marcxml2marcjson:marcxml2marcjson($r)
            return fn:concat('[ ', fn:string-join($objects, ", "), ']')
    else if ($o eq "xml") then
        if (count($source) eq 1) then
            marcjson2marcxml:marcjson2marcxml($source, "marklogic")
        else
            let $records := 
                for $r in $source
                return marcjson2marcxml:marcjson2marcxml($r, "marklogic")
            return
                element marcxml:collection {
                    $records
                }
    else if ($o eq "snelson") then
        $source
    else
        $source

return $output
(:
return 
    element debug {
        element input {
            attribute type {$i}
        },
        element output {
            attribute type {$o},
            attribute records {fn:count($output//marcxml:record)}
        },
        element output-data {
            $output
        }
    }
:)
(: return fn:count($output//*:triple) :)
