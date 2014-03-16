xquery version "3.0";

(:
:   Module Name: MARC/XML BIB 2 BIBFRAME RDF using Saxon
:
:   Module Version: 1.0
:
:   Date: 2012 December 03
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: Zorba (expath)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Transforms MARC/XML Bibliographic records
:       to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:       N-triples, or JSON.
:
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="http://location/of/marcxml.xml" -e serialization:="rdfxml" -e baseuri:="http://your-base-uri/"
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="../location/of/marcxml.xml" -e serialization:="rdfxml" -e baseuri:="http://your-base-uri/"
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
import module namespace http            =   "http://zorba.io/modules/http-client";
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://zorba.io/modules/xml";
import module namespace jx              =   "http://zorba.io/modules/json-xml";
import schema namespace parseoptions    =   "http://zorba.io/modules/xml-options";

import module namespace marcxml2marcjson = "http://3windmills.com/marcxq/modules/marcxml2marcjson#" at "../modules/module.MARCXML-2-MARCJSON.xqy";
import module namespace marcjson2marcxml = "http://3windmills.com/marcxq/modules/marcjson2marcxml#" at "../modules/module.MARCJSON-2-MARCXML.xqy";
import module namespace marc27092xmljson = "http://3windmills.com/marcxq/modules/marc27092xmljson#" at "../modules/module.ISO2709-2-MARC.xqy";

(: import module namespace xqilla = "http://xqilla.sourceforge.net/Functions" at "../modules/module.JSON-2-SnelsonXML.xqy"; :)

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";

declare namespace an = "http://www.zorba-xquery.com/annotations";
declare namespace httpexpath = "http://expath.org/ns/http-client";

(:~
:   This variable is for the location of the source MARC.
:)
declare variable $s as xs:string external;

(:~
:   Set the input serialization. Expected values are: xml (default), json
:)
declare variable $i as xs:string external;

(:~
:   Set the output serialization. Expected values are: xml (default), json
:)
declare variable $o as xs:string external;

let $source := 
    if ( fn:starts-with($s, "http://" ) or fn:starts-with($s, "https://" ) ) then
        let $json := http:get($s)
        return $json("body")("content")
    else
        file:read-text($s)

let $source := 
    if ($i eq "xml") then
        let $marcxml := parsexml:parse($source, <parseoptions:options/>)/element()
        return $marcxml//marcxml:record
    else if ($i eq "json") then
        let $json := jn:parse-json($source)
        return jx:json-to-xml($json)
    else
        $source

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
        if (count($source/*:item) eq 1) then
            marcjson2marcxml:marcjson2marcxml($source, "snelson")
        else
            let $records := 
                for $r in $source/*:item
                return marcjson2marcxml:marcjson2marcxml($r, "snelson")
            return
                element marcxml:collection {
                    $records
                }
    else if ($o eq "snelson") then
        $source
    else
        $source

return $output
