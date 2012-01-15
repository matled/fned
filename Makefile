gem:
	gem build fned.gemspec

bump:
	ruby -i -pe '$$_.sub!(/(\d+)"/) { |m| (m.to_i + 1).to_s + %%"% }' \
	    lib/fned/version.rb
	grep VERSION lib/fned/version.rb

.PHONY: bump gem
