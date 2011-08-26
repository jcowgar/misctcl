VERSION=0.2
TCLSH=tclsh85
DOCEXTRACT=../docextract.tcl
MAN_SRC = xmlgen.man

all: manual package

package: manual
	mkdir xmlgen-$(VERSION)
	cp xmlgen.tcl pkgIndex.tcl man/xmlgen.html xmlgen-$(VERSION)
	7z a xmlgen-$(VERSION).zip xmlgen-$(VERSION)
	rm -r xmlgen-$(VERSION)

manual: $(MAN_SRC)

.PHONY: manual

%.man: %.tcl
	$(TCLSH) $(DOCEXTRACT) -html -o man $<

