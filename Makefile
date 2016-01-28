DISTDIR = lecture7
TARBALL = $(DISTDIR).tar.gz
dist:
	tar czf $(TARBALL) $(DISTDIR)

clean:
	rm $(TARBALL)
