module Stinker
  class BlobEntry
    # Gets the String SHA for this blob.
    attr_reader :sha

    # Gets the full path String for this blob.
    attr_reader :path

    # Gets the Fixnum size of this blob.
    attr_reader :size

    def initialize(sha, path, size = nil)
      @sha  = sha
      @path = path
      @size = size
      @dir  = @name = @blob = nil
    end

    # Gets the normalized directory path String for this blob.
    def dir
      @dir ||= self.class.normalize_dir(::File.dirname(@path))
    end

    # Gets the file base name String for this blob.
    def name
      @name ||= ::File.basename(@path)
    end

    # Gets a Grit::Blob instance for this blob.
    #
    # repo - Grit::Repo instance for the Grit::Blob.
    #
    # Returns an unbaked Grit::Blob instance.
    def blob(repo)
      @blob ||= Grit::Blob.create(repo,
        :id => @sha, :name => name, :size => @size)
    end

    # Gets a Page instance for this blob.
    #
    # site - Stinker::Site instance for the Stinker::Page
    #
    # Returns a Stinker::Page instance.
    def page(site, commit)
      blob = self.blob(site.repo)
      page = site.page_class.new(site).populate(blob, self.dir)
      page.version = commit
      page
    end

    # Gets a File instance for this blob.
    #
    # site - Stinker::Site instance for the Stinker::Page
    #
    # Returns a Stinker::File instance.
    def file(site, commit)
      blob = self.blob(site.repo)
      file = site.file_class.new(site).populate(blob, commit, self.dir)
      file
    end

    def inspect
      %(#<Stinker::BlobEntry #{@sha} #{@path}>)
    end

    # Normalizes a given directory name for searching through tree paths.
    # Ensures that a directory begins with a slash, or
    #
    #   normalize_dir("")      # => ""
    #   normalize_dir(".")     # => ""
    #   normalize_dir("foo")   # => "/foo"
    #   normalize_dir("/foo/") # => "/foo"
    #   normalize_dir("/")     # => ""
    #   normalize_dir("c:/")   # => ""
    #
    # dir - String directory name.
    #
    # Returns a normalized String directory name, or nil if no directory
    # is given.
    def self.normalize_dir(dir)
      return '' if dir =~ /^.:\/$/
      if dir
        dir = ::File.expand_path(dir, '/')
        dir = '' if dir == '/'
      end
      dir
    end
  end
end
