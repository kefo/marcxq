xquery version "1.0";

(:
:   Module Name: MARC/JSON 2 MARC/XML
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
:   Module Overview:    Just lovely.  Because there is no standard way to perform
:       a basic JSON to XML transform, XQuery implementers have all done it
:       differently (I'm lookin at YOU MarkLogic) if at all.  So, one function 
:       for possible JSON format type
:
:)
   
(:~
:   Takes JSON formatted as XML and converts to MARC/XML
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since March 10, 2014
:   @version 1.0
:)
module namespace    marcjson2marcxml    =   "http://3windmills.com/marcxq/modules/marcjson2marcxml#";

declare namespace   marcxml             =   "http://www.loc.gov/MARC21/slim";
declare namespace   map                 =   "http://marklogic.com/xdmp/map";
declare namespace   snelson             =   "http://john.snelson.org.uk/parsing-json-into-xquery";

(:~
:   This is the main function.  Input RDF/XML, output ntiples.
:   All other functions are local.
:
:   @param  $rdfxml        node() is the RDF/XML  
:   @return ntripes as xs:string
:)
declare function marcjson2marcxml:marcjson2marcxml(
    $jsonxml as element(),
    $engine as xs:string
    ) as element(marcxml:record) {
    
    if ($engine eq "marklogic") then
        marcjson2marcxml:marklogic($jsonxml)
    else
        marcjson2marcxml:snelson($jsonxml)
};


(:~
:   This is the main function.  Input RDF/XML, output ntiples.
:   All other functions are local.
:
:   @param  $rdfxml        node() is the RDF/XML  
:   @return ntripes as xs:string
:)
declare function marcjson2marcxml:marklogic(
    $jsonxml as element()
    ) as element(marcxml:record) {
        
    let $leader := element marcxml:leader { xs:string($jsonxml/leader[1]) }
    let $controlfields := 
        for $e in $jsonxml/fields/map:map/map:entry[fn:starts-with(@key, "00")]
        return 
            element marcxml:controlfield {
                attribute {"tag"} { xs:string($e/@key) },
                xs:string($e/map:value[1])
            }
    let $datafields := 
        for $e in $jsonxml/fields/map:map/map:entry[fn:not(fn:starts-with(@key, "00"))]
        let $tag := xs:string($e/@key)
        let $ind1 := xs:string($e/map:value/map:map/map:entry[@key eq "ind1"]/map:value)
        let $ind2 := xs:string($e/map:value/map:map/map:entry[@key eq "ind2"]/map:value)
        let $subfields := 
            for $sf in $e/map:value/map:map/map:entry[@key eq "subfields"]/map:value/map:map/map:entry
            return 
                element marcxml:subfield { 
                    attribute {"code"} {xs:string($sf/@key)},
                    xs:string($sf/map:value) 
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
            $controlfields,
            $datafields
        }
};


(:~
:   This is the main function.  Input RDF/XML, output ntiples.
:   All other functions are local.
:
:   @param  $rdfxml        node() is the RDF/XML  
:   @return ntripes as xs:string
:)
declare function marcjson2marcxml:snelson(
    $jsonxml as element()
    ) as element(marcxml:record) {
        
    let $leader := element marcxml:leader { $jsonxml/snelson:pair[@name="leader"][1]/text() }
    let $controlfields := 
        for $e in $jsonxml/snelson:pair[@name="fields"]/snelson:item/snelson:pair[fn:starts-with(xs:string(@name), "00")]
        return 
            element marcxml:controlfield {
                attribute {"tag"} { $e/@name },
                $e/text()
            }
    let $datafields :=
        for $e in $jsonxml/snelson:pair[@name = "fields"]/snelson:item/snelson:pair[fn:not(fn:starts-with(@name, "00"))]
        let $tag := xs:string($e/@name)
        let $ind1 := $e/snelson:pair[@name = "ind1"]/text()
        let $ind2 := $e/snelson:pair[@name = "ind2"]/text()
        let $subfields := 
            for $sf in $e/snelson:pair[@name = "subfields"]/snelson:item/snelson:item/snelson:pair
            return 
                element marcxml:subfield { 
                    attribute {"code"} {xs:string($sf/@name)},
                    $sf/text()
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
            $controlfields,
            $datafields
        }
};