xquery version "1.0";

(:
:   Module Name: MARC/ISO2709 2 MARC/JSON or MARC/XML
:
:   Module Version: 1.0
:
:   Date: 2014 March 13
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Takes MARC/ISO2709 converts to JSON conforming
:       to http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
:       or MARC/XML.  Default is MARC/XML
:
:)
   
(:~
:   Takes MARC/ISO2709 converts to JSON conforming
:   to http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
:   or MARC/XML.  Default is MARC/XML
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since March 13, 2014
:   @version 1.0
:)
module namespace    marc27092xmljson   = "http://3windmills.com/marcxq/modules/marc27092xmljson#";

declare namespace   marcxml         = "http://www.loc.gov/MARC21/slim";


(:~
:   This is the main function.  Input MARC 2709, output xml or json.
:
:   @param  $iso2709 as xs:string (UTF-8!)
:   @return 
:)
declare function marc27092xmljson:marc27092xmljson(
    $iso2709 as xs:string
    )
{
    marc27092xmljson:marc27092xmljson($iso2709, "xml")
};

(:~
:   This is the main function.  Input MARC 2709, output xml or json.
:
:   @param  $iso2709 as xs:string (UTF-8!)
:   @param  $output as xs:string, json or xml
:   @return 
:)
declare function marc27092xmljson:marc27092xmljson(
    $iso2709 as xs:string,
    $output as xs:string
    )
{
    (:
        The utf8 string - the input iso2709 - needs to be normalized using 
        "canonical decomposition," which "decomposes" all the characters that
        are normally precomposed.  See, e.g.:
        http://www.unicode.org/reports/tr15/
        
        Then, the string needs to be converted to codepoints for a couple of 
        reasons.  One: the moment a non-standard character is encountered 
        by the XQuery parser, it may raise an error.  Two: we need to account 
        for multi-byte characters which are represented as a single codepoint, 
        or character in the string.
        
        By iterating over the codepoints, you can detect which are multi-byte
        and pad as appropriate.
    :)
    let $codepoints := fn:string-to-codepoints(fn:normalize-unicode($iso2709, "NFD"))
    let $codepoints := 
        for $a at $pos in $codepoints
        return
            if ($a < 128) then
                $a
            else if ($a > 127 and $a < 2048) then
                ($a, 0)
            else if ($a > 2047 and $a < 65536) then
                ($a, 0, 0)
            else
                ($a, 0, 0, 0)
        
    let $group-separators := fn:index-of($codepoints, 29)
    let $records-as-codepoints := 
            for $gs at $pos in $group-separators
            let $s := 
                if ($pos eq 1) then
                    0
                else
                    $group-separators[$pos - 1]
            let $e := $gs
            let $r := 
                for $cp at $p in $codepoints
                where $p > $s and $p < $e
                return $cp
            where fn:count($r) > 23
            return 
                element r {
                    attribute order {$pos},
                    attribute codepoints {$r}
            }
        
    let $records := 
        for $racpts at $racpos in $records-as-codepoints
        let $rac := 
            for $i in fn:tokenize($racpts/@codepoints, " ")
            return xs:int($i)
        let $leader := fn:codepoints-to-string(fn:subsequence($rac, 1, 24))
        let $baseoffset := xs:int(fn:substring($leader, 13, 5))
        
        let $record-seperators := fn:index-of($rac, 30)
        let $directory := fn:subsequence($rac, 1, ($record-seperators[1] - 1))
        let $directory := fn:codepoints-to-string($directory)
        let $directory := fn:substring($directory, 25)
    
        let $dentries-count := fn:string-length($directory) div 12
        let $dentries := 
            element directory-entries {
                for $x in (1 to $dentries-count)
                let $pos := 
                    if ($x eq 1) then
                        13
                    else
                        ($x * 12) + 1 
                let $d := fn:substring($directory, $pos - 12, 12)
                let $tag := fn:substring($d, 1, 3)
                let $field-length := xs:int(fn:substring($d, 4, 4)) 
                let $field-start := xs:int(fn:substring($d, 8, 5))
                return 
                    element d {
                        attribute tag {$tag},
                        attribute field-length {$field-length},
                        attribute field-start {$field-start},
                        $d
                    }
            }
        
        let $fields := 
            for $d at $p in $dentries/d
            let $t := $d/@tag
            let $field-start := $d/@field-start
            let $field-length := $d/@field-length

            let $start := $baseoffset + $field-start
            let $end := $baseoffset + $field-start + $field-length
            let $fieldpoints := 
                for $a at $pos in $rac
                where $pos > $start and $pos < $end
                return $a
                
            return 
                if ( xs:int($t) < 10 ) then
                    if ($output eq "json") then
                        fn:concat('{ "', xs:string($t), '": "', fn:codepoints-to-string($fieldpoints), '" }')
                    else
                        element controlfield {
                            attribute tag {$t},
                            fn:codepoints-to-string($fieldpoints)
                        }
                else 
                    let $ind1 := fn:codepoints-to-string($fieldpoints[1])
                    (:
                    try {
                            fn:codepoints-to-string($fieldpoints[1])
                        } catch ($e) {
                            let $prevd := $dentries/d[$p -1]
                            let $field-start := $prevd/@field-start
                            let $field-length := $prevd/@field-length
            
                            let $start := $baseoffset + $field-start
                            let $end := $baseoffset + $field-start + $field-length
                            let $fieldpoints := 
                                for $a at $pos in $codepoints
                                where $pos > $start and $pos < $end
                                return $a
                            return $fieldpoints
                        }
                    :)
                    let $ind2 := fn:codepoints-to-string($fieldpoints[2])
                    (:
                    try {
                            fn:codepoints-to-string($fieldpoints[2])
                        } catch ($e) {
                            let $prevd := $dentries/d[$p -1]
                            let $field-start := $prevd/@field-start
                            let $field-length := $prevd/@field-length
            
                            let $start := $baseoffset + $field-start
                            let $end := $baseoffset + $field-start + $field-length
                            let $fieldpoints := 
                                for $a at $pos in $codepoints
                                where $pos > $start and $pos < $end
                                return $a
                            return $fieldpoints
                        }
                    :)
                    let $uses := fn:index-of($fieldpoints, 31)
                    let $subfields := 
                        for $us at $pos in $uses
                        let $s := $us
                        let $e := 
                            if ($uses[$pos + 1]) then
                                $uses[$pos + 1]
                            else
                                9999
                        let $sfpoints := 
                            for $fp at $pos in $fieldpoints
                            where $pos > $s and $pos < $e
                            return 
                                if ($fp ne 0 and $fp ne 30 and $fp ne 31 and $fp ne 29) then
                                    $fp
                                else
                                    ()
                        return
                            if ($output eq "json") then
                                fn:concat('{ "', fn:codepoints-to-string($sfpoints[1]), '": "', marc27092xmljson:clean_string(fn:codepoints-to-string(fn:subsequence($sfpoints, 2))), '" }')
                            else
                                element subfields {
                                    attribute code {fn:codepoints-to-string($sfpoints[1])},
                                    fn:codepoints-to-string(fn:subsequence($sfpoints, 2))
                                }
                    return
                        if ($output eq "json") then
                            let $subfields := fn:concat('[ ', fn:string-join($subfields, ", "), ' ]')
                            return fn:concat('{ "', $t, '": { "ind1": "', $ind1, '", "ind2": "', $ind2, '", "subfields": [ ', $subfields, '] } }')
                        else
                            element datafield {
                                attribute tag {$t},
                                attribute ind1 {$ind1},
                                attribute ind2 {$ind2},
                                $subfields
                            }

        let $record := 
            if ($output eq "json") then
                let $leader := fn:concat('"leader": "', $leader, '"')
                let $fields := fn:concat('"fields": [ ', fn:string-join($fields, ", "), ' ]')
                return fn:concat('{ ', $leader, ', ', $fields, ' }')
            else
                <marcxml:record xmlns:marcxml="http://www.loc.gov/MARC21/slim">
                    {
                        element marcxml:leader { $leader },
                        $fields   
                    }
                </marcxml:record>
        (: where $racpos < 17 :)
        order by xs:int($racpts/@order)
        return $record
        
    return
        if (fn:count($records) > 1) then
            if ($output eq "json") then
                fn:concat('[ ', fn:string-join($records, ", "), ']')
            else
                <marcxml:collection xmlns:marcxml="http://www.loc.gov/MARC21/slim">
                    {$records}
                </marcxml:collection>
        else
            $records
};


(:~
:   Clean string of odd characters.
:
:   @param  $string       string to clean
:   @return xs:string
:)
declare function marc27092xmljson:clean_string($str as xs:string) as xs:string
 {
    let $str := fn:replace( $str, '\\', '\\\\')
    let $str := fn:replace( $str , '&quot;' , '\\"')
    let $str := fn:replace( $str, "\n", "\\r\\n")
    let $str := fn:replace( $str, "’", "'")
    let $str := fn:replace( $str, '“|”', '\\"')
    (: let $str := fn:replace( $str, 'ā', '\\u0101') :)
    return $str
};
