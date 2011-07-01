module Stinker
  class Site
    include Pagination

    class << self
      # Sets the page class used by all instances of this Wiki.
      attr_writer :page_class

      # Sets the file class used by all instances of this Wiki.
      attr_writer :file_class

      # Sets the markup class used by all instances of this Wiki.
      attr_writer :markup_class

      # Sets the default ref for the site.
      attr_accessor :default_ref

      # Sets the default name for commits.
      attr_accessor :default_committer_name

      # Sets the default email for commits.
      attr_accessor :default_committer_email

      # Sets sanitization options. Set to false to deactivate
      # sanitization altogether.
      attr_writer :sanitization

      # Sets sanitization options. Set to false to deactivate
      # sanitization altogether.
      attr_writer :history_sanitization

      # Gets the page class used by all instances of this Wiki.
      # Default: Stinker::Page.
      def page_class
        @page_class ||
          if superclass.respond_to?(:page_class)
            superclass.page_class
          else
            ::Stinker::Page
          end
      end

      # Gets the file class used by all instances of this Wiki.
      # Default: Stinker::File.
      def file_class
        @file_class ||
          if superclass.respond_to?(:file_class)
            superclass.file_class
          else
            ::Stinker::File
          end
      end

      # Gets the markup class used by all instances of this Wiki.
      # Default: Stinker::Markup
      def markup_class
        @markup_class ||
          if superclass.respond_to?(:markup_class)
            superclass.markup_class
          else
            ::Stinker::Markup
          end
      end

      # Gets the default sanitization options for current pages used by
      # instances of this Wiki.
      def sanitization
        if @sanitization.nil?
          @sanitization = Sanitization.new
        end
        @sanitization
      end

      # Gets the default sanitization options for older page revisions used by
      # instances of this Wiki.
      def history_sanitization
        if @history_sanitization.nil?
          @history_sanitization = sanitization ?
            sanitization.history_sanitization  :
            false
        end
        @history_sanitization
      end
    end

    self.default_ref = 'master'
    self.default_committer_name  = 'Anonymous'
    self.default_committer_email = 'anon@anon.com'

    # The String base path to prefix to internal links. For example, when set
    # to "/site", the page "Hobbit" will be linked as "/site/Hobbit". Defaults
    # to "/".
    attr_reader :base_path

    # Gets the sanitization options for current pages used by this Wiki.
    attr_reader :sanitization

    # Gets the sanitization options for older page revisions used by this Wiki.
    attr_reader :history_sanitization

    # Gets the String ref in which all page files reside.
    attr_reader :ref

    # Gets the String directory in which all page files reside.
    attr_reader :page_file_dir
    
    # Gets the Hash of content types (which define meta).
    attr_reader :content_types

    # Gets the Hash of site config
    attr_reader :site_config


    # Public: Initialize a new Stinker Repo.
    #
    # path    - The String path to the Git repository that holds the Stinker
    #           site.
    # options - Optional Hash:
    #           :base_path     - String base path for all Wiki links.
    #                            Default: "/"
    #           :page_class    - The page Class. Default: Stinker::Page
    #           :file_class    - The file Class. Default: Stinker::File
    #           :markup_class  - The markup Class. Default: Stinker::Markup
    #           :sanitization  - An instance of Sanitization.
    #           :page_file_dir - String the directory in which all page files reside
    #           :ref - String the repository ref to retrieve pages from
    #
    # Returns a fresh Stinker::Repo.
    def initialize(path, options = {})
      if path.is_a?(GitAccess)
        options[:access] = path
        path             = path.path
      end
      @path          = path
      @page_file_dir = options[:page_file_dir]
      @access        = options[:access]        || GitAccess.new(path, @page_file_dir)
      @base_path     = options[:base_path]     || "/"
      @page_class    = options[:page_class]    || self.class.page_class
      @file_class    = options[:file_class]    || self.class.file_class
      @markup_class  = options[:markup_class]  || self.class.markup_class
      @repo          = @access.repo
      @ref           = options[:ref] || self.class.default_ref
      @sanitization  = options[:sanitization]  || self.class.sanitization
      @history_sanitization = options[:history_sanitization] ||
        self.class.history_sanitization
      @content_types = options[:content_types] || {:page => []}
      @site_config = load_config_file || {}
      @access.clear
  
    end

    # Public: figure out the config  if it exists.
    # Returns a hash of the config
    def load_config_file
      conf_file = self.file('config.yaml')
      conf_file ||= self.file('config.yml')
      if conf_file
        YAML.load(conf_file.raw_data)
      end
    end

    # Public: check whether the site's git repo exists on the filesystem.
    #
    # Returns true if the repo exists, and false if it does not.
    def exist?
      @access.exist?
    end

    # Public: Get the formatted page for a given page name.
    #
    # name    - The human or canonical String page name of the site page.
    # version - The String version ID to find (default: @ref).
    #
    # Returns a Stinker::Page or nil if no matching page was found.
    def page(name, version = @ref)
      @page_class.new(self).find(name, version)
    end

    # Public: Get the static file for a given name.
    #
    # name    - The full String pathname to the file.
    # version - The String version ID to find (default: @ref).
    #
    # Returns a Stinker::File or nil if no matching file was found.
    def file(name, version = @ref)
      @file_class.new(self).find(name, version)
    end

    # Public: Create an in-memory Page with the given data and format. This
    # is useful for previewing what content will look like before committing
    # it to the repository.
    #
    # name   - The String name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    #
    # Returns the in-memory Stinker::Page.
    def preview_page(name, data, format)
      page = @page_class.new(self)
      ext  = @page_class.format_to_ext(format.to_sym)
      name = @page_class.cname(name) + '.' + ext
      blob = OpenStruct.new(:name => name, :data => data)
      page.populate(blob)
      page.version = @access.commit('master')
      page
    end

    # Public: Write a new version of a page to the Stinker repo root.
    #
    # name   - The String name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Grit::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Stinker::Committer instance.  If provided,
    #                       assume that this operation is part of batch of 
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the 
    # Stinker::Committer instance if this is part of a batch update.
    def write_page(name, format, data, commit = {})
      multi_commit = false

      committer = if obj = commit[:committer]
        multi_commit = true
        obj
      else
        Committer.new(self, commit)
      end

      committer.add_to_index('', name, format, data)

      committer.after_commit do |index, sha|
        @access.refresh
        index.update_working_dir('', name, format)
      end

      multi_commit ? committer : committer.commit
    end

    # Public: Write a new version of a page to the Stinker repo root.
    #
    # name   - The String name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    # meta_data   - The Hash representing the metadata
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Grit::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Stinker::Committer instance.  If provided,
    #                       assume that this operation is part of batch of 
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the 
    # Stinker::Committer instance if this is part of a batch update.
    def write_page_with_meta(name, format, data, meta_data, commit = {})
      write_page(name, format, combine_data(data, meta_data), commit)
    end

    # Public: Update an existing page with new content. The location of the
    # page inside the repository will not change. If the given format is
    # different than the current format of the page, the filename will be
    # changed to reflect the new format. If meta is already in the file,
    # it will be preserved
    #
    # page   - The Stinker::Page to update.
    # name   - The String extension-less name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Grit::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Stinker::Committer instance.  If provided,
    #                       assume that this operation is part of batch of 
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the 
    # Stinker::Committer instance if this is part of a batch update.
    def update_page(page, name, format, data, commit = {})
      name   ||= page.name
      format ||= page.format
      meta   = page.meta_data
      dir      = ::File.dirname(page.path)
      dir      = '' if dir == '.'
      multi_commit = false

      committer = if obj = commit[:committer]
        multi_commit = true
        obj
      else
        Committer.new(self, commit)
      end
      
      data = combine_data(data, meta)
      if page.name == name && page.format == format
        committer.add(page.path, normalize(data))
      else
        committer.delete(page.path)
        committer.add_to_index(dir, name, format, data, :allow_same_ext)
      end

      committer.after_commit do |index, sha|
        @access.refresh
        index.update_working_dir(dir, page.name, page.format)
        index.update_working_dir(dir, name, format)
      end

      multi_commit ? committer : committer.commit
    end

    # Public: Update an existing page with new content. The location of the
    # page inside the repository will not change. If the given format is
    # different than the current format of the page, the filename will be
    # changed to reflect the new format.
    #
    # page   - The Stinker::Page to update.
    # name   - The String extension-less name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    # meta_data   - The Hash metadata, nil to wipe data
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Grit::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Stinker::Committer instance.  If provided,
    #                       assume that this operation is part of batch of 
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the 
    # Stinker::Committer instance if this is part of a batch update.
    def update_page_with_meta(page, name, format, data, meta_data, commit = {})
      page.set_meta_data(meta_data)
      update_page(page, name, format, data, commit)
    end


    # Public: Delete a page.
    #
    # page   - The Stinker::Page to delete.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Grit::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Stinker::Committer instance.  If provided,
    #                       assume that this operation is part of batch of 
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the 
    # Stinker::Committer instance if this is part of a batch update.
    def delete_page(page, commit)
      multi_commit = false

      committer = if obj = commit[:committer]
        multi_commit = true
        obj
      else
        Committer.new(self, commit)
      end

      committer.delete(page.path)

      committer.after_commit do |index, sha|
        dir = ::File.dirname(page.path)
        dir = '' if dir == '.'

        @access.refresh
        index.update_working_dir(dir, page.name, page.format)
      end

      multi_commit ? committer : committer.commit
    end

    # Public: Applies a reverse diff for a given page.  If only 1 SHA is given,
    # the reverse diff will be taken from its parent (^SHA...SHA).  If two SHAs
    # are given, the reverse diff is taken from SHA1...SHA2.
    #
    # page   - The Stinker::Page to delete.
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    # commit - The commit Hash details:
    #          :message - The String commit message.
    #          :name    - The String author full name.
    #          :email   - The String email address.
    #          :parent  - Optional Grit::Commit parent to this update.
    #
    # Returns a String SHA1 of the new commit, or nil if the reverse diff does
    # not apply.
    def revert_page(page, sha1, sha2 = nil, commit = {})
      if sha2.is_a?(Hash)
        commit = sha2
        sha2   = nil
      end

      patch     = full_reverse_diff_for(page, sha1, sha2)
      committer = Committer.new(self, commit)
      parent    = committer.parents[0]
      committer.options[:tree] = @repo.git.apply_patch(parent.sha, patch)
      return false unless committer.options[:tree]
      committer.after_commit do |index, sha|
        @access.refresh

        files = []
        if page
          files << [page.path, page.name, page.format]
        else
          # Grit::Diff can't parse reverse diffs.... yet
          patch.each_line do |line|
            if line =~ %r{^diff --git b/.+? a/(.+)$}
              path = $1
              ext  = ::File.extname(path)
              name = ::File.basename(path, ext)
              if format = ::Stinker::Page.format_for(ext)
                files << [path, name, format]
              end
            end
          end
        end

        files.each do |(path, name, format)|
          dir = ::File.dirname(path)
          dir = '' if dir == '.'
          index.update_working_dir(dir, name, format)
        end
      end

      committer.commit
    end

    # Public: Applies a reverse diff to the repo.  If only 1 SHA is given,
    # the reverse diff will be taken from its parent (^SHA...SHA).  If two SHAs
    # are given, the reverse diff is taken from SHA1...SHA2.
    #
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    # commit - The commit Hash details:
    #          :message - The String commit message.
    #          :name    - The String author full name.
    #          :email   - The String email address.
    #
    # Returns a String SHA1 of the new commit, or nil if the reverse diff does
    # not apply.
    def revert_commit(sha1, sha2 = nil, commit = {})
      revert_page(nil, sha1, sha2, commit)
    end

    # Public: Lists all pages for this site.
    #
    # treeish - The String commit ID or ref to find  (default:  @ref)
    #
    # Returns an Array of Stinker::Page instances.
    def pages(treeish = nil)
      tree_list(treeish || @ref)
    end

    # Public: Returns the number of pages accessible from a commit
    #
    # ref - A String ref that is either a commit SHA or references one.
    #
    # Returns a Fixnum
    def size(ref = nil)
      tree_map_for(ref || @ref).inject(0) do |num, entry|
        num + (@page_class.valid_page_name?(entry.name) ? 1 : 0)
      end
    rescue Grit::GitRuby::Repository::NoSuchShaFound
      0
    end

    # Public: Search all pages for this site.
    #
    # query - The string to search for
    #
    # Returns an Array with Objects of page name and count of matches
    def search(query)
      args = [{}, '-i', '-c', query, @ref, '--']
      args << '--' << @page_file_dir if @page_file_dir

      @repo.git.grep(*args).split("\n").map! do |line|
        result = line.split(':')
        file_name = Stinker::Page.canonicalize_filename(::File.basename(result[1]))

        {
          :count  => result[2].to_i,
          :name   => file_name
        }
      end
    end

    # Public: All of the versions that have touched the Page.
    #
    # options - The options Hash:
    #           :page     - The Integer page number (default: 1).
    #           :per_page - The Integer max count of items to return.
    #
    # Returns an Array of Grit::Commit.
    def log(options = {})
      @repo.log(@ref, nil, log_pagination_options(options))
    end

    # Public: Refreshes just the cached Git reference data.  This should
    # be called after every Stinker update.
    #
    # Returns nothing.
    def clear_cache
      @access.refresh
    end

    # Public: Creates a Sanitize instance using the Wiki's sanitization
    # options.
    #
    # Returns a Sanitize instance.
    def sanitizer
      if options = sanitization
        @sanitizer ||= options.to_sanitize
      end
    end

    # Public: Creates a Sanitize instance using the Wiki's history sanitization
    # options.
    #
    # Returns a Sanitize instance.
    def history_sanitizer
      if options = history_sanitization
        @history_sanitizer ||= options.to_sanitize
      end
    end

    #########################################################################
    #
    # Internal Methods
    #
    #########################################################################

    # The Grit::Repo associated with the site.
    #
    # Returns the Grit::Repo.
    attr_reader :repo

    # The String path to the Git repository that holds the Stinker site.
    #
    # Returns the String path.
    attr_reader :path

    # Gets the page class used by all instances of this Wiki.
    attr_reader :page_class

    # Gets the file class used by all instances of this Wiki.
    attr_reader :file_class

    # Gets the markup class used by all instances of this Wiki.
    attr_reader :markup_class

    # Normalize the data.
    #
    # data - The String data to be normalized.
    #
    # Returns the normalized data String.
    def normalize(data)
      data.gsub(/\r/, '')
    end

    # Assemble a Page's filename from its name and format.
    #
    # name   - The String name of the page (may be in human format).
    # format - The Symbol format of the page.
    #
    # Returns the String filename.
    def page_file_name(name, format)
      ext = @page_class.format_to_ext(format)
      @page_class.cname(name) + '.' + ext
    end

    # Combine meta data and data into a single string.
    #
    # data   - The String data of a file
    # meta   - The Hash of meta data
    #
    # Returns the combined String, with meta in YAML attached to the top.
    def combine_data(data, meta)
      meta.empty? ? data : YAML.dump(meta) + "\n---\n" + data
    end



    # Fill an array with a list of pages.
    #
    # ref - A String ref that is either a commit SHA or references one.
    #
    # Returns a flat Array of Stinker::Page instances.
    def tree_list(ref)
      sha    = @access.ref_to_sha(ref)
      commit = @access.commit(sha)
      tree_map_for(sha).inject([]) do |list, entry|
        next list unless @page_class.valid_page_name?(entry.name)
        list << entry.page(self, commit)
      end
    end

    # Creates a reverse diff for the given SHAs on the given Stinker::Page.
    #
    # page   - The Stinker::Page to scope the patch to, or a String Path.
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    #
    # Returns a String of the reverse Diff to apply.
    def full_reverse_diff_for(page, sha1, sha2 = nil)
      sha1, sha2 = "#{sha1}^", sha1 if sha2.nil?
      args = [{:R => true}, sha1, sha2]
      if page
        args << '--' << (page.respond_to?(:path) ? page.path : page.to_s)
      end
      repo.git.native(:diff, *args)
    end

    # Creates a reverse diff for the given SHAs.
    #
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    #
    # Returns a String of the reverse Diff to apply.
    def full_reverse_diff(sha1, sha2 = nil)
      full_reverse_diff_for(nil, sha1, sha2)
    end

    # Gets the default name for commits.
    #
    # Returns the String name.
    def default_committer_name
      @default_committer_name ||= \
        @repo.config['user.name'] || self.class.default_committer_name
    end

    # Gets the default email for commits.
    #
    # Returns the String email address.
    def default_committer_email
      @default_committer_email ||= \
        @repo.config['user.email'] || self.class.default_committer_email
    end

    # Gets the commit object for the given ref or sha.
    #
    # ref - A string ref or SHA pointing to a valid commit.
    #
    # Returns a Grit::Commit instance.
    def commit_for(ref)
      @access.commit(ref)
    rescue Grit::GitRuby::Repository::NoSuchShaFound
    end

    # Finds a full listing of files and their blob SHA for a given ref.  Each
    # listing is cached based on its actual commit SHA.
    #
    # ref - A String ref that is either a commit SHA or references one.
    #
    # Returns an Array of BlobEntry instances.
    def tree_map_for(ref)
      @access.tree(ref)
    rescue Grit::GitRuby::Repository::NoSuchShaFound
      []
    end
  end
end
