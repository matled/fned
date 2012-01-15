#!/usr/bin/env ruby
require 'tempfile'

module Fned
  class EditList
    class InvalidLine < StandardError
      attr_reader :line

      def initialize(message, line)
        @line = line
        super(message)
      end

      def to_s
        super + " on line #{line}"
      end
    end

    class UserAbort < StandardError
    end

    def initialize(options = {})
      @options = {
        :separator => ' ',
      }.merge(options)

      # Do not use characters in lower and upper case, the line numbers
      # are case insensitive.
      @digits = ('0'..'9').to_a + ('A'..'Z').to_a
      @digits_upcase = @digits.map { |s| s.upcase }

      @escape = {
        "\r" => "\\r",
        "\n" => "\\n",
        "\\" => "\\\\",
      }
    end

    # editor to run from environment or
    def editor
      # TODO: check for existence of editor, vim, emacs?
      ENV["VISUAL"] || ENV["EDITOR"] || "vi"
    end

    # replace according to a hash
    def replace(replacements, str)
      r = Regexp.new(replacements.keys.map { |s| Regexp.quote(s) }.join("|"))
      str.gsub(r) { |s| replacements[s] }
    end

    # escape string using @escape
    def escape(str)
      replace(@escape, str)
    end

    # unescape string using @escape
    def unescape(str)
      replace(@escape.invert, str)
    end

    # encode number using @digits, padding is minimum number of digits
    def number_encode(n, padding = 1)
      result = []
      raise ArgumentError if n < 0
      raise ArgumentError if padding < 1
      until n == 0
        n, k = n.divmod(@digits.length)
        result << @digits[k]
      end
      result.fill(@digits[0], result.length, padding - result.length)
      result.reverse.join
    end

    # decode number using @digits
    def number_decode(str)
      str.upcase.chars.map do |char|
        n = @digits_upcase.index(char)
        return nil unless n
        n
      end.inject(0) do |m, e|
        m * @digits.length + e
      end
    end

    # write comment to io
    def write_comment(io, comments)
      comments.lines.map(&:chomp).each do |s|
        io.puts "# #{escape(s.to_s)}"
      end
    end

    # write number and item to io
    def write_item(io, index, padding, str)
      io.puts number_encode(index, padding) + @options[:separator] +
        escape(str.to_s)
    end

    # write items and comments to io
    def write_file(io, items, comments)
      padding = number_encode([items.length - 1, 0].max).length
      items.each_with_index do |item, index|
        write_comment(io, comments[index]) if comments[index]
        write_item(io, index, padding, item)
      end
      write_comment(io, comments[items.length]) if comments[items.length]
    end

    # read from io and parse content
    def read_file(io, count)
      @result = Array.new(count)
      line_number = 0
      io.each do |line|
        line_number += 1
        line = line.chomp
        if line =~ /\A\s*(?:#|\z)/
          next
        end

        key, value = line.split(@options[:separator], 2)
        index = number_decode(key)
        value = unescape(value)

        if index.nil?
          raise InvalidLine.new("index #{key.inspect} contains invalid " +
                                "characters", line_number)
        end
        if index >= count
          raise InvalidLine.new("index #{key.inspect} too large", line_number)
        end
        if @result[index]
          raise InvalidLine.new("index #{key.inspect} used multiple times",
                                line_number)
        end

        @result[index] = value
      end
      @result
    end

    # ask user for retry
    def retry?
      loop do
        $stderr.print "Edit / Abort? [Ea] "
        $stderr.flush
        case $stdin.readline.strip
        when "", /\Ae/i
          return true
        when /\Aa/i
          return false
        end
      end
    end

    # return dup of string with binary encoding
    def bin_dup(str)
      str = str.to_s.dup
      str.force_encoding "binary"
      str
    end

    # start editor to edit items, returns new list of items
    def edit(items, comments)
      # Ensure all strings are in binary encoding as filenames may have
      # invalid encodings.
      items = items.map { |item| bin_dup(item) }
      comments = comments.map { |comment| bin_dup(comment) if comment }

      Tempfile.open(File.basename($0), :encoding => "binary") do |fh|
        write_file(fh, items, comments)
        fh.close
        begin
          # TODO: return code of editor meaningful?
          system(editor, fh.path)
          File.open(fh.path, "r", :encoding => "binary") do |io|
            return read_file(io, items.length)
          end
        rescue InvalidLine => e
          warn e.message
          if retry?
            retry
          else
            raise UserAbort
          end
        end
      end
    end
  end
end
