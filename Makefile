DISTDIR = lecture6
TARBALL = $(DISTDIR).tar.gz

all: $(DISTDIR)
	./compile.sh

$(DISTDIR):
	mkdir -p $@

check: all
	./check.sh

dist: all
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)
