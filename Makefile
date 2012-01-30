VERSION = $(shell cat VERSION)
FILES = $(shell git ls-files)

gem: fned-$(VERSION).gem

install: fned-$(VERSION).gem
	gem install $<

fned-$(VERSION).gem: $(FILES)
	gem build fned.gemspec

bump:
	@git diff --cached --exit-code HEAD > /dev/null || \
	    (echo Cannot bump with dirty index.; exit 1)
	ruby -i -pe '$$_.sub!(/(\d+)$$/) { |m| (m.to_i + 1).to_s }' VERSION
	$(MAKE) lib/fned/version.rb
	git add VERSION lib/fned/version.rb
	git commit -m "version $$(cat VERSION)"
	git tag -s -m "version $$(cat VERSION)" "v$$(cat VERSION)"

lib/fned/version.rb: VERSION
	printf 'module Fned\n  VERSION = "%s"\nend\n' $(shell cat VERSION) > $@

fned.1: README
	ronn --pipe --roff $< > $@

README.html: README
	ronn --pipe --html $< > $@

clean:
	rm -f fned-*.gem fned.1 README.html

.PHONY: gem install bump clean
