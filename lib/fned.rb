require 'optparse'
require 'fned/filename_edit'

module Fned
  def self.main(*args, &block)
    FilenameEdit.main(*args, &block)
  end
end
