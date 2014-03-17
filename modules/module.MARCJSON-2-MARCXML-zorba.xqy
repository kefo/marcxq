xquery version "1.0";

(:
:   Module Name: MARC/JSON 2 MARC/XML, using Zorba 3.x
:
:   Module Version: 1.0
:
:   Date: 2014 March 16
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: zorba-jsoniq
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Transforms MARC/JSON, passed as Zorba JSON object,
:       to MARC/XML.  Zorba has a native way of iterating over JSON, without
:       first formatting it as XML.  JSONIQ.
:
:)
   
(:~
:   Takes JSON formatted as XML and converts to MARC/XML
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since March 16, 2014
:   @version 1.0
:)
module namespace    marcjson2marcxml-zorba    =   "http://3windmills.com/marcxq/modules/marcjson2marcxml-zorba#";

declare namespace   marcxml             =   "http://www.loc.gov/MARC21/slim";

(:~
:   This is the main function.  Transforms MARC/JSON, passed as Zorba JSON object,
:   to MARC/XML.  Zorba has a native way of iterating over JSON, without
:   first formatting it as XML.  JSONIQ.
:
:   @param  $json        object()
:   @return element(marcxml:record)
:)
declare function marcjson2marcxml-zorba:marcjson2marcxml(
    $json
    ) as element() {
        
    if ( fn:count(jn:members($json)) > 1 ) then
        let $records := 
            for $r in jn:members($json)
            return marcjson2marcxml-zorba:transform-record($r)
        return
            element marcxml:collection {
                $records
            }
    else
        marcjson2marcxml-zorba:transform-record($json)

};


(:~
:   This is the main function.  Transforms MARC/JSON, passed as Zorba JSON object,
:   to MARC/XML.  Zorba has a native way of iterating over JSON, without
:   first formatting it as XML.  JSONIQ.
:
:   @param  $json        object()
:   @return element(marcxml:record)
:)
declare function marcjson2marcxml-zorba:transform-record(
    $object
    ) as element(marcxml:record) {
    let $leader := element marcxml:leader { $object("leader") }
    let $fields := 
        for $e in jn:members($object("fields"))
            for $k in jn:keys($e)
            return 
                if (fn:starts-with($k, "00")) then
                    element marcxml:controlfield {
                        attribute {"tag"} { xs:string($k) },
                        xs:string($e($k))
                    }
                else
                    let $tag := xs:string($k)
                    let $ind1 := xs:string($e($k)("ind1"))
                    let $ind2 := xs:string($e($k)("ind1"))
                    let $subfields := 
                        for $sf in jn:members($e($k)("subfields"))
                            for $sfk in jn:keys($sf)
                            return 
                                element marcxml:subfield { 
                                    attribute {"code"} {xs:string($sfk)},
                                    xs:string($sf($sfk)) 
                                }
                    return 
                        element marcxml:datafield {
                            attribute {"tag"} { $tag },
                            attribute {"ind1"} { $ind1 },
                            attribute {"ind2"} { $ind2 },
                            $subfields
                        }
    return
        element marcxml:record {
            $leader,
            $fields
        }
};
