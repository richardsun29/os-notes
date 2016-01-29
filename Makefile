DISTDIR = lecture6
HTML = $(DISTDIR)/index.html
MARKDOWN = index.md
TARBALL = $(DISTDIR).tar.gz

all: $(DISTDIR) $(HTML)

$(DISTDIR):
	mkdir -p $@

$(HTML): compile.sh $(MARKDOWN)
	./compile.sh

check: $(HTML)
	./check.sh

dist: $(DISTDIR) $(HTML)
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)
