# Copyright (C) 2012 Matthias Lederhofer <matled@gmx.net>
#
# This file is part of fned.
#
# fned is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# fned is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with fned.  If not, see <http://www.gnu.org/licenses/>.
require 'optparse'
require 'pathname'
require 'fned/edit_list'
require 'fned/rename'
require 'fned/version'

module Fned
  class FilenameEdit
    def self.main(*args)
      # Filenames may be in any encoding, i.e. have an invalid encoding if
      # the default encoding is not binary.  Therefore ensure that every
      # argument is in binary encoding.
      args = args.map { |str| str.dup.force_encoding "binary" }

      options = {}

      option_parser = OptionParser.new do |parser|
        parser.version = VERSION

        parser.banner = "Usage: #{File.basename($0)} [options] <files..>"

        parser.on("-v", "--verbose", "verbose output") do |v|
          options[:verbose] = true
        end

        parser.on("-r", "--recursive", "rename files in all subdirectories") do |v|
          options[:recursive] = true
        end

        parser.on("-sSEPARATOR", "--separator=SEPARATOR", "separator between line number and filename") do |v|
          options[:separator] = v
        end
      end

      begin
        option_parser.parse!(args)
      rescue OptionParser::ParseError
        warn $!.message
        return false
      end

      if args.empty?
        $stderr.puts option_parser.help
        return false
      end

      self.new(args, options).run
    end

    def initialize(paths, options = {})
      @paths = paths.map { |path| Pathname.new(path) }
      @options = {
        :verbose => false,
        :recursive => false,
      }.merge(options)

      if @options[:recursive]
        @paths = @paths.map { |path| [path] + walk(path) }.flatten
      end

      # Ensure all paths are in binary encoding, otherwise comparison
      # wont work after reading the files back from the file.
      @paths.map! { |path| Pathname.new(path.to_s.force_encoding("binary")) }
      # Don't display the same path multiple times.
      @paths.uniq!
      # It is not possible to rename `.' and `..'.
      @paths.reject! { |path| %w(. ..).include?(path.basename.to_s) }

      @errors = []
    end

    # Recursively walk through path and return path of all entries.
    # Does not include path itself.
    def walk(path)
      # TODO: descend into symlinked directories?
      # TODO: handle errors (ENOENT, ENOTDIR, ELOOP, EACCESS)
      return [path] unless path.lstat.directory?

      entries = path.entries
      .map do |entry|
        entry.to_s.force_encoding "binary"
      end
      .reject do |entry|
        %w(. ..).include?(entry)
      end
      .map do |entry|
        if (path + entry).lstat.directory?
          path + "#{entry}/"
        else
          path + entry
        end
      end
      .sort_by do |entry|
        [entry.lstat.directory? ? 0 : 1, entry.basename]
      end

      result = []
      result += entries
      result += entries.map do |entry|
        if entry.lstat.directory?
          walk(entry)
        end
      end.compact.flatten
      result
    end

    def edit
      # TODO: option to edit the full path or relative path instead of
      # basename only
      # TODO: hide filename extension
      items = @paths.map(&:basename).map(&:to_s)

      # add path before each block of files in the same directory
      comments = []
      dir = nil
      @paths.each.with_index do |path, index|
        next if path.dirname == dir
        comments[index] = "#{path.dirname}/"
        dir = path.dirname
      end

      items_new = EditList.new(@options).edit(items, comments)

      items_new.map.with_index do |path, index|
        # TODO: Pathname#dirname + path breaks if path contains ..
        # because .. is resolved by removing one component which may
        # change the directory if symlinks are in the path.
        @paths[index].dirname + path if path
      end
    end

    def run
      rename = Rename.new(@options)
      @paths.zip(edit).each do |source, destination|
        # TODO: option to delete files (interatively?) that are dropped
        # from the list
        next unless destination
        rename.add(source, destination)
      end
      rename.rename_files.empty?
    end
  end
end
