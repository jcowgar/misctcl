#
# Example Excel Export
#

lappend auto_path ../xmlgen .

package require ::msoffice::excel

::msoffice::excel x -properties {
    Author {Tcl Msoffice Excel}
}

x style define
x style add Default -font Trebuchet -fontsize 10
x style add Header -font Trebuchet -fontbold yes -justify Center \
    -border {-1 -1 2 -1} -background #cacaca
x style enddefine

x worksheet begin People -columnwidths {100 100}
x row begin
x cell -data Name -style Header
x cell -data Age -style Header
x row end

foreach {name age} {John 22 Jim 32 Jeff 18 Jack 44 Joe 87} {
    x row begin
    x cell -data $name
    x cell -data $age
    x row end
}

x worksheet end

x toFile excel_example.xml

