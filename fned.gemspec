lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'fned/version'

Gem::Specification.new do |s|
  s.name = "fned"
  s.version = Fned::VERSION
  s.author = "Matthias Lederhofer"
  s.email = "matled@gmx.net"
  s.homepage = "http://github.com/matled/fned/"
  s.summary = "rename files with your favorite editor"
  s.description = File.read("README")
  s.executable = "fned"
  s.extra_rdoc_files = %w(README)
  s.files = %w(
    COPYING
    README
    bin/fned
    lib/fned.rb
    lib/fned/rename.rb
    lib/fned/edit_list.rb
    lib/fned/filename_edit.rb
    lib/fned/version.rb
  )
  s.license = "GPL"
  s.require_path = "lib"
end
