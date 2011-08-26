#
# Microsoft Office - Excel handling
#

package require xmlgen

package provide ::msoffice::excel 0.1

namespace eval ::msoffice {
    snit::type excel {
        option -properties -default {}
        
        variable didFooter 0
        variable buf {}
        
        constructor {args} {
            $self configurelist $args
            
            ::xmlgen xml -indentsize 2 -wrap 80
            
            lappend $options(-properties) \
                Created [clock format [clock seconds] -gmt 1 -format {%Y-%m-%dT%TZ}]
            
            $self DocHeader
        }
        
        method DocHeader {} {
            xml raw "<?mso-application progid=\"Excel.Sheet\"?>\n"
            xml open Workbook \
                xmlns      "urn:schemas-microsoft-com:office:spreadsheet" \
                xmlns:o    "urn:schemas-microsoft-com:office:office" \
                xmlns:x    "urn:schemas-microsoft-com:office:excel" \
                xmlns:ss   "urn:schemas-microsoft-com:office:spreadsheet" \
                xmlns:html "http://www.w3.org/TR/REC-html40"
            
            xml open DocumentProperties \
                xmlns "urn:schemas-microsoft-com:office:office"

            foreach {pname pval} $options(-properties) {
                xml content $pname $pval
            }

            xml close
        }
        
        method DocFooter {} {
            if {$didFooter} {
                return
            }
            
            xml close
        }
        
        method StyleAdd args {
            set styleAttrs {}
            set cellAttrs {}
            set fontAttrs {}
            set alignAttrs {}
            set interiorAttrs {}
            
            set border {}
            set borderColor {}
            set format {}
            
            set name [lindex $args 0]
            lappend styleAttrs ss:ID $name ss:Name $name
            
            set idx 1
            foreach {arg val} [lrange $args 1 end] {
                switch -- $arg {
                    -font { 
                        lappend fontAttrs ss:FontName $val
                    }
                    -fontsize {
                        lappend fontAttrs ss:FontSize $val
                    }
                    -fontcolor {
                        lappend fontAttrs ss:Color $val
                    }
                    -bold {
                        if {$val} {
                            lappend fontAttrs ss:Bold 1
                        } else {
                            lappend fontAttrs ss:Bold 0
                        }
                    }
                    -parent { 
                        lappend styleAttrs ss:Parent $val
                    }
                    -verticalalign { 
                        lappend alignAttrs ss:Vertical $val
                    }
                    -justify {
                        lappend alignAttrs ss:Horizontal $val
                    }
                    -wrap {
                        lappend alignAttrs ss:WrapText $val
                    }
                    -background {
                        if {[llength $val] == 1} {
                            lappend interiorAttrs ss:Color $val ss:Pattern Solid 
                        } else {
                            lappend interiorAttrs \
                                ss:Color [lindex $val 0] \
                                ss:Pattern [lindex $val 1]
                        }
                    }
                    -border { 
                        switch [llength $val] {
                            1 {
                                set border [list $val $val $val $val]
                            }
                            2 {
                                lassign $val lr tb
                                set border [list $tb $lr $tb $lr]
                            }
                            4 {
                                set border $val
                            }
                            default {
                                error "-border must be 1, 2 or 4 elements."
                            }
                        }
                    }
                    -bordercolor { 
                        switch [llength $val] {
                            1 {
                                set borderColor [list $val $val $val $val]
                            }
                            2 {
                                lassign $val lr tb
                                set borderColor [list $tb $lr $tb $lr]
                            }
                            4 {
                                set borderColor $val
                            }
                            default {
                                error "-bordercolor must be 1, 2 or 4 elements."
                            }
                        }
                    }
                    -format { 
                        set format $val
                    }
                }
            }
            
            xml open Style {*}$styleAttrs
            if {[llength $alignAttrs] > 0} {
                xml one Alignment {*}$alignAttrs
            }
            if {[llength $fontAttrs] > 0} {
                xml one Font {*}$fontAttrs
            }
            if {[llength $interiorAttrs] > 0} {
                xml one Interior {*}$interiorAttrs
            }
            if {$border == {} && $borderColor == {}} {
                xml one Borders
            } else {
                if {$border == {}} {
                    set border [lrepeat 4 1]
                }
                if {$borderColor == {}} {
                    set borderColor [lrepeat 4 #000000]
                }
                
                xml open Borders
                
                set borderNames {Top Right Bottom Left}
                foreach n $borderNames b $border c $borderColor {
                    if {$b == -1} {
                        continue
                    }
                    
                    xml one Border ss:Position $n ss:Weight $b ss:Color $c ss:LineStyle Continuous
                }
                
                xml close
            }

            switch -- $format {
                {} {
                    # Do nothing
                }
                shortdate {
                    xml one NumberFormat ss:Format "mm/dd/yyyy"
                }
                comma {
                    xml one NumberFormat \
                        ss:Format "_(* #,##0_);_(* \(#,##0\);_(* &quot;-&quot;??_);_(@_)"
                }
                currency {
                    xml one NumberFormat \
                        ss:Format "_(&quot;$&quot;* #,##0.00_);_(&quot;$&quot;* \(#,##0.00\);_(&quot;$&quot;* &quot;-&quot;??_);_(@_)"
                }
                default {
                    xml one NumberFormat ss:Format $format
                }
            }
            
            xml close ;# Style
        }
        
        method style {option args} {
            switch -- $option {
                define {
                    xml open Styles
                }
                enddefine {
                    xml close ;# Styles
                }
                add {
                    $self StyleAdd {*}$args
                }
            }
        }

        method WorksheetBegin {name args} {
            set columnWidths {}
            foreach {arg val} $args {
                switch -- $arg {
                    -columnwidths {
                        set columnWidths $val
                    }
                    default {
                        error "Invalid option '$arg' passed"
                    }
                }
            }
            
            xml open Worksheet ss:Name $name
            xml open Table
            
            if {[llength $columnWidths] > 0} {
                foreach w $columnWidths {
                    if {$w == {auto}} {
                        xml one Column ss:AutoFitWidth 1
                    } else {
                        xml one Column ss:AutoFitWidth 0 ss:Width $w
                    }
                }
            }
        }
        
        method WorksheetEnd {args} {
            xml close ;# Table
            xml close ;# Worksheet
        }
        
        method worksheet {option args} {
            switch -- $option {
                begin { $self WorksheetBegin {*}$args }
                end { $self WorksheetEnd {*}$args }
            }
        }
        
        method row {option args} {
            switch -- $option {
                begin { 
                    xml open Row
                }
                end { 
                    xml close ;# Row
                }
            }
        }
        
        method cell {args} {
            set cellAttributes {}
            set dataAttributes {}
            set data           {}
            
            foreach {arg val} $args {
                switch -- $arg {
                    -type {
                        lappend dataAttributes ss:Type $val
                    }
                    -data {
                        set data $val
                    }
                    -formula {
                        lappend cellAttributes ss:Formula $val
                    }
                    -style {
                        lappend cellAttributes ss:StyleID $val
                    }
                    -index {
                        lappend cellAttributes ss:Index $val
                    }
                    -span {
                        lappend cellAttributes ss:MergeAcross [expr {$val - 1}]
                    }
                    -rowspan {
                        lappend cellAttributes ss:MergeDown [expr {$val - 1}]
                    }
                    default {
                        error "Invalid option `$arg` passed"
                    }
                }
            }
            
            xml open Cell {*}$cellAttributes
            
            if {[llength $dataAttributes] > 0 || $data != {}} {
                if {[lsearch $dataAttributes ss:Type] == -1} {
                    lappend dataAttributes ss:Type String 
                }
                
                xml content Data $data {*}$dataAttributes
            }
            
            xml close ;# Cell
        }
        
        method asXml {} {
            $self DocFooter
            return [xml get]
        }
        
        method toFile {filename} {
            $self DocFooter
            
            xml toFile $filename
        }
    }
}

