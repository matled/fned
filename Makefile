VERSION = $(shell cat VERSION)
FILES = $(shell git ls-files)

gem: fned-$(VERSION).gem

install: fned-$(VERSION).gem
	gem install $<

fned-$(VERSION).gem: $(FILES)
	gem build fned.gemspec

bump:
	ruby -i -pe '$$_.sub!(/(\d+)$$/) { |m| (m.to_i + 1).to_s }' VERSION
	$(MAKE) lib/fned/version.rb

lib/fned/version.rb: VERSION
	printf 'module Fned\n  VERSION = "%s"\nend\n' $(shell cat VERSION) > $@

clean:
	rm -f fned-*.gem

.PHONY: gem install bump clean
