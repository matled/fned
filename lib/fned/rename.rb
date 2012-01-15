module Fned
  class Rename
    def initialize(options = {})
      @options = {
        :verbose => false,
      }.merge(options)

      @renames = {}
    end

    def verbose?
      @options[:verbose]
    end

    # add source, destination to list of intended renames
    def add(source, destination)
      @renames[source] = destination
    end

    # rename the added files, return array of errors
    def rename_files
      @errors = []
      # Rename in reverse order of source filename such that directories
      # will be renamed after all files within the directory have been
      # renamed.
      # TODO: implement more advanced strategies for renaming
      # dependencies including cyclic dependencies (i.e. swapping
      # filenames)
      @renames.sort_by { |src, dst| src }.reverse.each do |src, dst|
        rename(src, dst)
      end
      @errors
    end

    # normalize path
    def normalize(path)
      # NOTE: removing /../ by removing the previous component of a path
      # is a bad idea as /symlink/../ is the parent directory of the
      # directory the symlink is pointing to, which is in general not
      # the same as /.
      path.to_s.
        # replace successive slashes
        gsub(%r{//+}, "/").
        # remove trailing slash
        sub(%r{/\z}, "").
        # replace /./
        gsub(%r{/\./}, "/").
        # remove ./ in the beginning and /. in the end
        gsub(%r{(?:\A\./|/\.\z)}, "")
    end

    # rename a single file
    def rename(source, destination)
      # Normalizing the paths has two reasons:
      # (1) renaming symlinks fails with trailing slashes but trailing
      #     slashes might be present if the symlink points to a directory
      # (2) comparison if source and destination are the same
      src, dst = normalize(source), normalize(destination)

      return if src == dst

      # TODO: racy, use link(src, dst); unlink(src)?
      if File.exist?(dst)
        warn "not renaming because target exists: %s -> %s" %
        [source.to_s.inspect, destination.to_s.inspect]
        return
      end

      begin
        # TODO: add cross filesystem rename
        puts "%s -> %s" % [source.to_s.inspect, destination.to_s.inspect] if verbose?
        File.rename(src, dst)
      rescue SystemCallError => error
        @errors << error
        # create a new exception to get the clean error message without
        # a filename
        warn "cannot rename %s: %s" % [source.to_s.inspect,
          SystemCallError.new(error.errno).message]
      end
    end
  end
end
