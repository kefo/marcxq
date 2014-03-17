xquery version "1.0";

(:
:   Module Name: MARC/JSON 2 MARC/XML, using Marklogic
:
:   Module Version: 1.0
:
:   Date: 2014 March 16
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: map:map
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Transforms MARC/JSON, passed as Marklogic map:map,
:       to MARC/XML.  Marklogic has a native way of iterating over JSON, without
:       first formatting it as XML.
:
:)
   
(:~
:   Takes JSON formatted as map:map item()* and converts to MARC/XML
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since March 16, 2014
:   @version 1.0
:)
module namespace    marcjson2marcxml-ml    =   "http://3windmills.com/marcxq/modules/marcjson2marcxml-ml#";

declare namespace   marcxml             =   "http://www.loc.gov/MARC21/slim";
declare namespace   map                 =   "http://marklogic.com/xdmp/map";

(:~
:   This is the main function.  Transforms MARC/JSON, passed as Marklogic map,
:   to MARC/XML.  MarkLogic has a native way of iterating over JSON, without
:   first formatting it as XML.
:
:   @param  $map        map:map()*
:   @return element()
:)
declare function marcjson2marcxml-ml:marcjson2marcxml(
    $map
    ) as element() {
    
    if (fn:count($map) > 1 ) then
        let $records := 
            for $m in $map
            return marcjson2marcxml-ml:record($m)
        return
            element marcxml:collection {
                $records
            }
    else
        marcjson2marcxml-ml:record($map)
};


(:~
:   Transform a single map:map representing a MARC Record in JSON to MARc/XML.
:
:   @param  $m      as map:map
:   @return element(marcxml:record)
:)
declare function marcjson2marcxml-ml:record(
    $m as map:map
    ) as element(marcxml:record) {
        
    let $leader := element marcxml:leader { xs:string(map:get($m, "leader")[1]) }
    let $fields :=
        for $f in map:get($m, "fields")
            for $k in map:keys($f)
            return
                if (fn:starts-with($k, "00")) then
                    element marcxml:controlfield {
                        attribute {"tag"} { xs:string($k) },
                        xs:string(map:get($f, $k)[1])
                    }
                else 
                    let $tag := xs:string($k)
                    let $ind1 := map:get(map:get($f, $k)[1], "ind1")[1]
                    let $ind2 := map:get(map:get($f, $k)[1], "ind2")[1]
                    let $subfields := 
                        for $sf in map:get(map:get($f, $k)[1], "subfields")
                            for $sfk in map:keys($sf)
                            return 
                                element marcxml:subfield { 
                                    attribute {"code"} {xs:string($sfk)},
                                    xs:string(map:get($sf, $sfk)[1])
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
