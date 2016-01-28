DISTDIR = lecture6
TARBALL = $(DISTDIR).tar.gz

all:
	./compile.sh

dist:
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)

