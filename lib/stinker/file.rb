module Stinker
  class File
    Site.file_class = self

    # Public: Initialize a file.
    #
    # site - The Stinker::Site in question.
    #
    # Returns a newly initialized Stinker::File.
    def initialize(site)
      @site = site
      @blob = nil
      @path = nil
    end

    # Public: The on-disk filename of the file.
    #
    # Returns the String name.
    def name
      @blob && @blob.name
    end

    # Public: The raw contents of the page.
    #
    # Returns the String data.
    def raw_data
      @blob && @blob.data
    end

    # Public: The Grit::Commit version of the file.
    attr_reader :version

    # Public: The String path of the file.
    attr_reader :path

    # Public: The String mime type of the file.
    def mime_type
      @blob.mime_type
    end

    #########################################################################
    #
    # Internal Methods
    #
    #########################################################################

    # Find a file in the given Stinker repo.
    #
    # name    - The full String path.
    # version - The String version ID to find.
    #
    # Returns a Stinker::File or nil if the file could not be found.
    def find(name, version)
      checked = name.downcase
      map     = @site.tree_map_for(version)
      if entry = map.detect { |entry| entry.path.downcase == checked }
        @path    = name
        @blob    = entry.blob(@site.repo)
        @version = version.is_a?(Grit::Commit) ? version : @site.commit_for(version)
        self
      end
    end
  end
end
