lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'rename_edit/version'

Gem::Specification.new do |s|
  s.name = "rename_edit"
  s.version = RenameEdit::VERSION
  s.author = "Matthias Lederhofer"
  s.email = "matled@gmx.net"
  s.homepage = "http://github.com/matled/rename_edit/"
  s.summary = "rename files with your favorite editor"
  s.description = File.read("README")
  s.executable = "rename-edit"
  s.extra_rdoc_files = %w(README)
  s.files = %w(
    COPYING
    README
    bin/rename-edit
    lib/rename_edit.rb
    lib/rename_edit/rename.rb
    lib/rename_edit/edit_list.rb
    lib/rename_edit/rename_edit.rb
    lib/rename_edit/version.rb
  )
  s.license = "GPL"
  s.require_path = "lib"
end
