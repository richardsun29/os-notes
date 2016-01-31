DISTDIR = lecture6
HTML = $(DISTDIR)/index.html
MARKDOWN = index.md
CSS = style.css
TARBALL = $(DISTDIR).tar.gz

all: $(HTML)

$(DISTDIR):
	mkdir -p $@

$(HTML): compile.sh $(DISTDIR) $(MARKDOWN) $(CSS)
	./compile.sh

check: $(HTML)
	./check.sh

dist: $(DISTDIR) $(HTML)
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)
