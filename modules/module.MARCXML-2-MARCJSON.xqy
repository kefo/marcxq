xquery version "1.0";

(:
:   Module Name: MARC/XML 2 MARC/JSON
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
:   Module Overview:    Takes MARC/XML converts to JSON conforming
:       to http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
:
:)
   
(:~
:   Takes MARC/XML and transforms to MARC/JSON conforming to
:   http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since March 10, 2014
:   @version 1.0
:)
module namespace    marcxml2marcjson   = "http://3windmills.com/marcxq/modules/marcxml2marcjson#";

declare namespace   marcxml         = "http://www.loc.gov/MARC21/slim";

(:~
:   This is the main function.  Input RDF/XML, output ntiples.
:   All other functions are local.
:
:   @param  $rdfxml        node() is the RDF/XML  
:   @return ntripes as xs:string
:)
declare function marcxml2marcjson:marcxml2marcjson(
    $marcxml as element(marcxml:record)
    ) as xs:string {
    
    let $leader := fn:concat('"leader": "', xs:string($marcxml/marcxml:leader), '"')
    let $controlfields := 
        for $f in $marcxml/marcxml:controlfield
        return fn:concat('{ "', xs:string($f/@tag), '": "', xs:string($f), '" }')
    let $datafields := 
        for $f in $marcxml/marcxml:datafield
        let $tag := xs:string($f/@tag)
        let $ind1 := xs:string($f/@ind1)
        let $ind2 := xs:string($f/@ind2)
        let $subfields := 
            for $sf in $f/marcxml:subfield
            return fn:concat('{ "', xs:string($sf/@code), '": "', marcxml2marcjson:clean_string(xs:string($sf)), '" }')
        let $subfields := fn:concat('[ ', fn:string-join($subfields, ", "), ' ]')
        return fn:concat('{ "', $tag, '": { "ind1": "', $ind1, '", "ind2": "', $ind2, '", "subfields": [ ', $subfields, '] } }')
    
    let $fields := ($controlfields,$datafields)
    let $fields := fn:concat('"fields": [ ', fn:string-join($fields, ", "), ' ]')
    return fn:concat('{ ', $leader, ', ', $fields, ' }')
};


(:~
:   Clean string of odd characters.
:
:   @param  $string       string to clean
:   @return xs:string
:)
declare function marcxml2marcjson:clean_string($str as xs:string) as xs:string
 {
    let $str := fn:replace( $str, '\\', '\\\\')
    let $str := fn:replace( $str , '&quot;' , '\\"')
    let $str := fn:replace( $str, "\n", "\\r\\n")
    let $str := fn:replace( $str, "’", "'")
    let $str := fn:replace( $str, '“|”', '\\"')
    (: let $str := fn:replace( $str, 'ā', '\\u0101') :)
    return $str
};