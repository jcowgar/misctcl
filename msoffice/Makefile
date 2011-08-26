VERSION=0.1
TCLSH=tclsh85
DOCEXTRACT=../docextract.tcl
MAN_SRC = excel.man

all: manual package

package: manual
	mkdir msoffice-$(VERSION)
	cp excel.tcl pkgIndex.tcl msoffice-$(VERSION)
	7z a msoffice-$(VERSION).zip msoffice-$(VERSION)
	rm -r msoffice-$(VERSION)

manual: $(MAN_SRC)

.PHONY: manual

%.man: %.tcl
	$(TCLSH) $(DOCEXTRACT) -html -o man $<

