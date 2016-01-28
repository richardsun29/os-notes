DISTDIR = lecture6
TARBALL = $(DISTDIR).tar.gz

all: $(DISTDIR)
	./compile.sh

$(DISTDIR):
	mkdir -p $@

dist: all
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)

