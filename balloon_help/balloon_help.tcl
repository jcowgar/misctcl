package require Tk
package require tkhtml

proc ::balloon {w help {delay 500}} {
	bind $w <Any-Enter> "after $delay [list ::balloon:show %W [list $help]]"
	bind $w <Any-Leave> "destroy %W.balloon"
}

proc ::balloon:show {w arg} {
	if {[eval winfo containing	[winfo pointerxy .]] != $w} {
		return
	}
	set top $w.balloon
	catch {destroy $top}
	toplevel $top -bd 1 -bg black
	wm overrideredirect $top 1
	if {$::tcl_platform(platform) == "macintosh"} {
		unsupported1 style $top floating sideTitlebar
	}
	pack [message $top.txt -aspect 10000 -bg lightyellow -font fixed -text $arg]
	set wmx [winfo rootx $w]
	set wmy [expr [winfo rooty $w]+[winfo height $w]]
	wm geometry $top [winfo reqwidth $top.txt]x[winfo reqheight $top.txt]+$wmx+$wmy
	raise $top
}

proc ::html_balloon {w help args} {
	set delay 500 ;# MS is reported to be defaulting to 500ms
	set css {}

	foreach {arg val} $args {
		switch -- $arg {
			-delay { set delay $val }
			-css { set css $val }
		}
	}

	bind $w <Any-Enter> "after $delay [list ::html_balloon:show %W [list $help] [list $css]]"
	bind $w <Any-Leave> "destroy %W.balloon"
}

proc ::html_balloon:show {w help css} {
	if {[eval winfo containing	[winfo pointerxy .]] != $w} {
		return
	}
	set top $w.balloon
	catch {destroy $top}
	toplevel $top -bg black
	wm overrideredirect $top 1

	if {$::tcl_platform(platform) == "macintosh"} {
		unsupported1 style $top floating sideTitlebar
	}

	html $top.t -shrink 1
	pack $top.t -pady {1 0}

	$top.t style "
		body {
			background-color: #ffffe1;
			margin: 0px;
			padding: 8px;
			font-size: 0.8em;
		}
		$css
	"
	$top.t parse -final $help
	update idletasks

	set wmx [winfo rootx $w]
	set wmy [expr [winfo rooty $w]+[winfo height $w]]

	set maxX [winfo screenwidth .]
	set maxY [winfo screenheight .]
	set width [expr [winfo reqwidth $top.t] + 2]
	set height [expr [winfo reqheight $top.t] + 2]

	if {[expr $width + $wmx] > $maxX} {
		set wmx [expr $maxX - $width]
	}
	if {[expr $height + $wmy + 32] > $maxY} {
		set wmy [expr [winfo rooty $w] - $height]
	}

	wm geometry $top ${width}x${height}+$wmx+$wmy
	raise $top
}

