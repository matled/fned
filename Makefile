gem:
	gem build rename_edit.gemspec

bump:
	ruby -i -pe '$$_.sub!(/(\d+)"/) { |m| (m.to_i + 1).to_s + %%"% }' \
	    lib/rename_edit/version.rb
	grep VERSION lib/rename_edit/version.rb

.PHONY: bump gem
