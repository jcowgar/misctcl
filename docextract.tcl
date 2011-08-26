#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

package require cmdline

proc main {} {
	if {[llength $::argv] == 0} {
		puts "Invalid usage, please use -help for help."
		exit 0
	}

	set options {
		{o.arg       "./"  "set the output directory"}
		{ext.arg     "man" "set the extension of the extracted document files"}
		{doctools.arg no    "generate HTML output via doctools package"}
		{all                "output output even when no valid comments where found"}
	}

	set usage "\[options] filename1 \[filename2] \[...]\noptions:"
	if {[catch {array set params [::cmdline::getoptions ::argv $options $usage]} msg]} {
		puts $msg
		exit 0
	}

	if {$params(doctools)} {
		package require doctools
	}

	file mkdir $params(o)

	foreach fname $::argv {
		set fh [open $fname r]
		set comments ""

		set inDocComment 0

		while {[gets $fh line] >=0} {
			set line [string trim $line]
			if {$inDocComment && [string index $line 0] != "#"} {
				set inDocComment 0
			} elseif {[string range $line 0 1]=="#*"} {
				set inDocComment 1
			} elseif {$inDocComment} {
				append comments "[string range $line 2 end]\n"
			}
		}

		close $fh

		if {$params(all) || [string length $comments] > 0} {
			set ofh [open [file join $params(o) [file rootname $fname].$params(ext)] w]
			puts $ofh $comments
			close $ofh

			if {$params(doctools)} {
				::doctools::new .dt -format html
				set html [.dt format $comments]

				set ofh [open [file join $params(o) [file rootname $fname].html] w]
				puts $ofh $html
				close $ofh
			}
		}
	}
}

main

