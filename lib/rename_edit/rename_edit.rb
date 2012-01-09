require 'pathname'
require 'rename_edit/edit_list'
require 'rename_edit/rename'

module RenameEdit
  class RenameEdit
    def self.main(*args)
      # Filenames may be in any encoding, i.e. have an invalid encoding if
      # the default encoding is not binary.  Therefore ensure that every
      # argument is in binary encoding.
      args = args.map do |str|
        str = str.dup
        str.force_encoding "binary"
        str
      end

      options = {}

      option_parser = OptionParser.new do |parser|
        parser.banner = "Usage: #{File.basename($0)} [options] <files..>"

        parser.on("-v", "--verbose", "verbose output") do |v|
          options[:verbose] = true
        end

        parser.on("-r", "--recursive", "rename files in all subdirectories") do |v|
          options[:recursive] = true
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

      RenameEdit.new(args, options).run
    end

    def initialize(paths, options = {})
      @paths = paths.map { |file| Pathname.new(file) }
      @options = {
        :verbose => false,
        :recursive => false,
      }.merge(options)

      if @options[:recursive]
        @paths = @paths.map { |path| walk(path) }.flatten
      end

      @errors = []
    end

    def walk(path)
      # TODO: descend into symlinked directories?
      # TODO: handle errors (ENOENT, ENOTDIR, ELOOP, EACCESS)
      return [path] unless path.lstat.directory?

      entries = path.entries.reject { |entry| %w(. ..).include?(entry.to_s) }
      entries.map! do |entry|
        if (path + entry).lstat.directory?
          path + "#{entry}/"
        else
          path + entry
        end
      end
      entries.sort_by! do |entry|
        [entry.lstat.directory? ? 0 : 1, entry.basename]
      end

      result = []
      unless %w(. ..).include?(path.basename.to_s)
        result << path
      end
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

      items_new = EditList.new.edit(items, comments)

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
