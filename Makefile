DISTDIR = lecture6
HTML = $(DISTDIR)/index.html
MARKDOWN = index.md
CSS = style.css
TARBALL = $(DISTDIR).tar.gz

all: $(DISTDIR) $(HTML)

$(DISTDIR):
	mkdir -p $@

$(HTML): compile.sh $(MARKDOWN) $(CSS)
	./compile.sh

check: $(HTML)
	./check.sh

dist: $(DISTDIR) $(HTML)
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)
