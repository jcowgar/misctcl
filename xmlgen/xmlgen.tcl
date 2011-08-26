#****
# [manpage_begin xmlgen n 0.2]
# [moddesc {Generate well formed XML files}]
# [copyright {Copyright 2010 Jeremy Cowgar. All Rights Reserved.}]
# [category {XML}]
# [require snit]
# [keywords xml]
# [description]
# Generate well formed XML files
#

package provide xmlgen 0.2

package require snit

snit::type ::xmlgen {
	option -indentsize -default 2
	option -wrap -default 80
	
	variable indent
	variable buf
	variable tags
	
	method AppendIndent {} {
		append buf [string repeat { } [expr {$indent * $options(-indentsize)}]]	
	}
	
	method AppendAttributes {tag args} {
		set extra { }
		if {$options(-wrap) > 0} {
			set size [expr {[string length $args] + 
				([llength $args] * 4) +
				($indent * $options(-indentsize)) +
				[string length $tag] + 3}]
			if {$size > $options(-wrap)} {
				set indentcount [expr {$options(-indentsize) * ($indent + 2)}]
				set extra "\n[string repeat { } $indentcount]"
			}
		}
		
		foreach {a v} $args {
			append buf "${extra}${a}=\"${v}\""
		}
	}
	
	#****
	# [section Construction]
	#
	# [list_begin definitions]
	#

	#****
	# [call [cmd {::xmlgen object}] \
	# [opt "[option -indentsize] [arg size]"] \
	# [opt "[option -wrap] [arg length]"] \
	# ]
	#
	# Create a new instance of the XMLGen object.
	#
	# [list_begin definitions]
	# [def "[option -indentsize] [arg size]"]
	# Each nested tag is indented [arg size].
	#
	# [def "[option -wrap] [arg length]"]
	# If a tag with it's attributes will span past [arg length] then it's attributes are placed
	# on their own line indented twice of [option -indentsize]. For example, if [option -wrap]
	# was 10 and [option -indentsize] was 2:
	# 
	# [example {
	# <mytag
	#	 name="John"
	#	 age="33">
	#   <child />
	# </mytag>
	# }]
	#
	# [list_end]
	
	constructor {args} {
		$self configurelist $args
		$self reset
	}
	
	#****
	# [list_end]
	#
	
	#****
	# [section Methods]
	#
	# [list_begin definitions]
	#
	
	#****
	# [call [cmd {object reset}]]
	# 
	# Reset the XML generator. This will allow you to use the same object multiple
	# times if desired.
	#
	
	method reset {} {
		set indent 0
		set buf "<?xml version=\"1.0\"?>\n"
		set tags {}
	}
    
    #****
    # [call [cmd {object raw}] [arg content]]
    #
    # Add raw [arg content] into the XML document.
    #
    # Note: This is raw data. It does not append any newline, does no formatting, wrapping
    # or even any indenting. You are responsible for all of that when appending raw data.
    #
    
    method raw {raw} {
        append buf $raw
    }
	
	#****
	# [call [cmd {object open}] [arg tagname] [arg args]]
	#
	# Open a new tag.
	#
	# [list_begin definitions]
	# [def "[arg tagname]"]
	# Tag to begin.
	#
	# [def "[arg args]"]
	# Attributes to associate with [arg tagname].
	#
	# [list_end]
	#
	# An example:
	#
	# [example {
	# object open person name John age 33
	#
	# # creates:
	# #   <person name="John" age="33">
	# }]
	#
	
	method open {tag args} {
		lappend tags $tag
		$self AppendIndent
		if {$args == {}} {
			append buf "<$tag>"
		} else {
			append buf "<$tag"
			$self AppendAttributes $tag {*}$args
			append buf ">"
		}
		append buf "\n"
		
		incr indent
	}
    
	#****
	# [call [cmd {object close}]]
	#
	# Closes an open tag
	#
	# An example:
	#
	# [example {
	# object open family
	# object open person name John
	# object close
	# object close
	#
	# # Creates:
	# # <family>
	# #   <person name="John">
	# #   </person>
	# # </family>
	# }]
	#
	
	method close {} {
		incr indent -1
		set closeTag [lindex $tags end]
		set tags [lrange $tags 0 end-1]
		$self AppendIndent
		append buf "</$closeTag>\n"
	}	
	
    #****
    # [call [cmd {object content}] [arg tag] [arg content] [arg attributes]]
    #
    # Add [arg tag] with [arg attributes] containing [arg content] to the XML document. This
    # opens and closes the tag.
    #
    # An example:
    # [example {
    # object open person
    # object content name {John Doe} sex Male
    # object close
    #
    # # Result:
    # # <person>
    # #   <name sex="Male">John Doe</name>
    # # </person>
    # }]
    #
    
    method content {tag content args} {
        $self AppendIndent
        append buf "<$tag"
        $self AppendAttributes $tag {*}$args
        append buf ">"
        append buf $content
        append buf "</$tag>\n"
    }
	
	#****
	# [call [cmd {object one}] [arg tagname] [arg args]]
	#
	# Opens and closes a new tag on one line.
	#
	# [list_begin definitions]
	# [def "[arg tagname]"]
	# Tag to begin.
	#
	# [def "[arg args]"]
	# Attributes to associate with [arg tagname].
	#
	# [list_end]
	#
	# An example:
	#
	# [example {
	# object one person name John age 33
	#
	# # creates:
	# #   <person name="John" age="33" />
	# }]
	#
	
	method one {tag args} {
		$self AppendIndent
		if {$args == {}} {
			append buf "<$tag />"
		} else {
			append buf "<$tag"
			$self AppendAttributes $tag {*}$args
			append buf " />"
		}
		append buf "\n"
	}
	
	#****
	# [call [cmd {object get}]]
	#
	# Returns the XML constructed as a string.
	#
	
	method get {} {
		return $buf
	}
	
	#****
	# [call [cmd {object toFile}] [arg filename]]
	#
	# Write the XML constructed to [arg filename].
	#
	# [list_begin definitions]
	# [def "[arg filename]"]
	# Filename to write XML content to.
	#
	# [list_end]
	#
	
	method toFile {filename} {
		set fh [open $filename w]
		puts $fh [$self get]
		close $fh
	}

	#****
	# [list_end]
	#
	# [section Examples]
	#
	# [example {
	# package require xmlgen
	# 
	# ::xmlgen x -indentsize 4 
	# x open root
	# x open families
	# x open parent first John last Doe city {Small Town} state {North Dakota} \
	#	 zip 55512 county Pole country {United States of America} age 32
	# x one spouse first Jennifer maiden Smith age 31
	# x one child first Jim age 13
	# x one child first Jill age 8
	# x close
	# x open parent first Jim
	# x one child first Joe
	# x close
	# x close
	# x close
	# x toFile people.xml
	# }]
	#
	# [section Todo]
	#
	# [section {Bugs, Ideas, Feedback}]
	# Provide feedback to Jeremy Cowgar <jeremy@cowgar.com>
	#
}

#****
# [manpage_end]

