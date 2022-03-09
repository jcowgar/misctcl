package require Tk

namespace eval ttk::combobox {}

# Required to escape a few characters due to the string match used.
proc ttk::combobox::EscapeKey { key } {
    switch -- $key {
        bracketleft  { return {\[} }
        bracketright { return {\]} }
        asterisk     { return {\*} }
        question     { return {\?} }
        quotedbl     { return {\"} }
        quoteright   -
        quoteleft    { return {\'} }
        default      { return $key }
    }
}

proc ttk::combobox::PrevNext { W dir } {
    set cur [$W current]

    switch -- $dir {
        up {
            if {$cur <= 0} {
                return
            }

            incr cur -1
        }
        down {
            incr cur

            if {$cur == [llength [$W cget -values]]} {
                return
            }
        }
    }

    $W current $cur
    event generate $W <<ComboboxSelected>> -when mark
}

proc ttk::combobox::CompleteEntry { W key } {
    if { [string length $key] > 1 && [string tolower $key] != $key } {
        return
    }

    if { [$W instate readonly] } {
        set value [EscapeKey $key]
    } else {
        set value [string map { {[} {\[} {]} {\]} {?} {\?} {*} {\*} } [$W get]]
        if { [string equal $value ""] } {
            return
        }
    }

    set values [$W cget -values]

    set start 0
    if { [string match -nocase $value* [$W get]] } {
        set start [expr { [$W current] + 1 }]
    }

    set x [lsearch -nocase -start $start $values $value*]
    if { $x < 0 } {
        if { $start > 0} {
            set x [lsearch -nocase $values $value*]

            if { $x < 0 } {
                return
            }
        } else {
            return
        }
    }

    set index [$W index insert]
    $W set [lindex $values $x]
    $W icursor $index
    $W selection range insert end

    if { [$W instate readonly] } {
        event generate $W <<ComboboxSelected>> -when mark
    }
}

proc ttk::combobox::CompleteList { W key { start -1 } } {
    after cancel {set ttk::combobox::keyaccumulator ""}

    set key [EscapeKey $key]

    append ttk::combobox::keyaccumulator $key
    set key $ttk::combobox::keyaccumulator
    after 250 {set ttk::combobox::keyaccumulator ""}

    if { $start == -1 } {
        set start [expr { [$W curselection] + 1 }]
    }

    for { set idx $start } { $idx < [$W size] } { incr idx } {
        if { [string match -nocase $key* [$W get $idx]] } {
            $W selection clear 0 end
            $W selection set $idx
            $W see $idx
            $W activate $idx
            return
        }
    }

    if { $start > 0 } {
        set ttk::combobox::keyaccumulator ""
        CompleteList $W $key 0
    }
}

bind ComboboxListbox <KeyPress>   { ttk::combobox::CompleteList %W %K }
bind ComboboxListbox <Alt-Up>     { ttk::combobox::LBSelected %W }

bind TCombobox       <KeyRelease> { ttk::combobox::CompleteEntry %W %K }
bind TCombobox       <Up>         { ttk::combobox::PrevNext %W up }
bind TCombobox       <Down>       { ttk::combobox::PrevNext %W down }
bind TCombobox       <Alt-Down>   { ttk::combobox::Post %W }
