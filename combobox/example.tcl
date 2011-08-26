source combobox.tcl

set values {One Two Three Four Five \"Hello 'Hello *Hello ?Hello [Hello] Six Seven Eight Nine Ten}

ttk::label .l1 -text Readonly
ttk::combobox .c1 -state readonly -values $values
ttk::label .l2 -text Editable
ttk::combobox .c2 -values $values

bind .c1 <<ComboboxSelected>> { puts [.c1 get] }
bind .c2 <<ComboboxSelected>> { puts [.c2 get] }

pack .l1 .c1 .l2 .c2
