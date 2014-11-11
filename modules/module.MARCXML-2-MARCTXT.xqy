xquery version "1.0";

(:
:   Module Name: MARC/XML 2 MARC/TXT
:
:   Module Version: 1.0
:
:   Date: 2010 Oct 18
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Takes MARC/XML converts to TXT conforming to a basic
:       representation.
:
:)
   
(:~
:   Takes MARC/XML and transforms to TXT conforming to a basic representation.
:
:   @author Kevin Ford (kefo@3windmills.com)
:   @since November 10, 2014
:   @version 1.0
:)
module namespace    marcxml2marctxt   = "http://3windmills.com/marcxq/modules/marcxml2marctxt#";

declare namespace   marcxml         = "http://www.loc.gov/MARC21/slim";

(:~
:   This is the main function.  Input RDF/XML, output ntiples.
:   All other functions are local.
:
:   @param  $marcxml        element(marcxml:record)*
:   @return xs:string
:)
declare function marcxml2marctxt:marcxml2marctxt(
    $marcxml as element()
    ) as xs:string 
{
    let $records := 
        if ( fn:local-name($marcxml) eq "record" ) then
            $marcxml
        else
            $marcxml//marcxml:record
    return
        if (fn:count($records) eq 1) then
            marcxml2marctxt:record($records)
        else
            let $objects := 
                for $r in $records
                return marcxml2marctxt:record($r)
            return fn:concat('[ ', fn:string-join($objects, ", "), ']')
};
        
(:~
:   Transform a single marcxml:record to MARC/TXT.
:
:   @param  $marcxml as element(marcxml:record)
:   @return xs:string
:)
declare function marcxml2marctxt:record(
    $marcxml as element(marcxml:record)
    ) as xs:string 
{
    let $leader := fn:concat('Leader: ', xs:string($marcxml/marcxml:leader))
    let $controlfields := 
        for $f in $marcxml/marcxml:controlfield
        return fn:concat(xs:string($f/@tag), '      ', xs:string($f))
    let $controlfields := fn:string-join($controlfields, fn:codepoints-to-string(10))
    let $datafields := 
        for $f in $marcxml/marcxml:datafield
        let $tag := xs:string($f/@tag)
        let $ind1 := xs:string($f/@ind1)
        let $ind2 := xs:string($f/@ind2)
        let $subfields := 
            for $sf in $f/marcxml:subfield
            return fn:concat("$", xs:string($sf/@code), marcxml2marctxt:clean_string(xs:string($sf)))
        let $subfields := fn:string-join($subfields, " ")
        return fn:concat($tag, '  ', $ind1, $ind2, '  ', $subfields)
    let $datafields := fn:string-join($datafields, fn:codepoints-to-string(10))
    
    let $fields := ($leader, $controlfields,$datafields)
    return fn:string-join($fields, fn:codepoints-to-string(10))
};


(:~
:   Clean string of odd characters.
:
:   @param  $string       string to clean
:   @return xs:string
:)
declare function marcxml2marctxt:clean_string($str as xs:string) as xs:string
 {
    let $str := fn:replace( $str, '\\', '\\\\')
    let $str := fn:replace( $str , '&quot;' , '\\"')
    let $str := fn:replace( $str, "\n", "\\r\\n")
    let $str := fn:replace( $str, "’", "'")
    let $str := fn:replace( $str, '“|”', '\\"')
    (: let $str := fn:replace( $str, 'ā', '\\u0101') :)
    return $str
};