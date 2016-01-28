DISTDIR = lecture6
TARBALL = $(DISTDIR).tar.gz

dist:
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm -rf $(TARBALL) $(DISTDIR)

