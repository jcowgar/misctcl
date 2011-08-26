#
# Simple XML Gen Example
#

lappend ::auto_path .

package require xmlgen

::xmlgen x -indentsize 4 
x open root
x open families
x open parent first John last Doe city {Small Town} state {North Dakota} \
	zip 55512 county Pole country {United States of America} age 32
x one spouse first Jennifer maiden Smith age 31
x one child first Jim age 13
x one child first Jill age 8
x close
x open parent first Jim
x one child first Joe
x close
x close
x close
puts [x get]
x toFile people.xml

