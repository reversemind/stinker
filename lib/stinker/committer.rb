module Stinker
  # Responsible for handling the commit process for a Site.  It sets up the 
  # Git index, provides methods for modifying the tree, and stores callbacks
  # to be fired after the commit has been made.  This is specifically 
  # designed to handle multiple updated pages in a single commit.
  class Committer
    # Gets the instance of the Stinker::Site that is being updated.
    attr_reader :site

    # Gets a Hash of commit options.
    attr_reader :options

    # Initializes the Committer.
    #
    # site    - The Stinker::Site instance that is being updated.
    # options - The commit Hash details:
    #           :message   - The String commit message.
    #           :name      - The String author full name.
    #           :email     - The String email address.
    #           :parent    - Optional Grit::Commit parent to this update.
    #           :tree      - Optional String SHA of the tree to create the
    #                        index from.
    #           :committer - Optional Stinker::Committer instance.  If provided,
    #                        assume that this operation is part of batch of 
    #                        updates and the commit happens later.
    #
    # Returns the Committer instance.
    def initialize(site, options = {})
      @site      = site
      @options   = options
      @callbacks = []
    end

    # Public: References the Git index for this commit.
    #
    # Returns a Grit::Index.
    def index
      @index ||= begin
        idx = @site.repo.index
        if tree   = options[:tree]
          idx.read_tree(tree)
        elsif parent = parents.first
          idx.read_tree(parent.tree.id)
        end
        idx
      end
    end

    # Public: The committer for this commit.
    #
    # Returns a Grit::Actor.
    def actor
      @actor ||= begin
        @options[:name]  = @site.default_committer_name  if @options[:name].to_s.empty?
        @options[:email] = @site.default_committer_email if @options[:email].to_s.empty?
        Grit::Actor.new(@options[:name], @options[:email])
      end
    end

    # Public: The parent commits to this pending commit.
    #
    # Returns an array of Grit::Commit instances.
    def parents
      @parents ||= begin
        arr = [@options[:parent] || @site.repo.commit(@site.ref)]
        arr.flatten!
        arr.compact!
        arr
      end
    end

    # Adds a page to the given Index.
    #
    # dir    - The String subdirectory of the Stinker::Page without any
    #          prefix or suffix slashes (e.g. "foo/bar").
    # name   - The String Stinker::Page name.
    # format - The Symbol Stinker::Page format.
    # data   - The String site data to store in the tree map.
    # allow_same_ext - A Boolean determining if the tree map allows the same
    #                  filename with the same extension.
    #
    # Raises Stinker::DuplicatePageError if a matching filename already exists.
    # This way, pages are not inadvertently overwritten.
    #
    # Returns nothing (modifies the Index in place).
    def add_to_index(dir, name, format, data, allow_same_ext = false)
      path = @site.page_file_name(name, format)
      if dir.strip.empty? && path =~ /\//
        path_parts = path.split('/')
        path = path_parts.pop
        path_parts.shift if path_parts.first.empty?
        dir = path_parts.join('/')
      end
      dir = '/' if dir.strip.empty?

      fullpath = ::File.join(*[@site.page_file_dir, dir, path].compact)
      fullpath = fullpath[1..-1] if fullpath =~ /^\//

      if index.current_tree && tree = index.current_tree / dir
        downpath = path.downcase.sub(/\.\w+$/, '')

        tree.blobs.each do |blob|
          next if page_path_scheduled_for_deletion?(index.tree, fullpath)
          file = blob.name.downcase.sub(/\.\w+$/, '')
          file_ext = ::File.extname(blob.name).sub(/^\./, '')
          if downpath == file && !(allow_same_ext && file_ext == ext)
            raise DuplicatePageError.new(dir, blob.name, path)
          end
        end
      end

      index.add(fullpath, @site.normalize(data))
    end

    # Update the given file in the repository's working directory if there
    # is a working directory present.
    #
    # dir    - The String directory in which the file lives.
    # name   - The String name of the page (may be in human format).
    # format - The Symbol format of the page.
    #
    # Returns nothing.
    def update_working_dir(dir, name, format)
      unless @site.repo.bare
        if @site.page_file_dir
          dir = dir.size.zero? ? @site.page_file_dir : ::File.join(dir, @site.page_file_dir)
        end

        path =
          if dir == ''
            @site.page_file_name(name, format)
          else
            ::File.join(dir, @site.page_file_name(name, format))
          end

        Dir.chdir(::File.join(@site.repo.path, '..')) do
          if file_path_scheduled_for_deletion?(index.tree, path)
            @site.repo.git.rm({'f' => true}, '--', path)
          else
            @site.repo.git.checkout({}, 'HEAD', '--', path)
          end
        end
      end
    end

    # Writes the commit to Git and runs the after_commit callbacks.
    #
    # Returns the String SHA1 of the new commit.
    def commit
      sha1 = index.commit(@options[:message], parents, actor, nil, @site.ref)
      @callbacks.each do |cb|
        cb.call(self, sha1)
      end
      sha1
    end

    # Adds a callback to be fired after a commit.
    #
    # block - A block that expects this Committer instance and the created 
    #         commit's SHA1 as the arguments.
    #
    # Returns nothing.
    def after_commit(&block)
      @callbacks << block
    end

    # Determine if a given page (regardless of format) is scheduled to be
    # deleted in the next commit for the given Index.
    #
    # map   - The Hash map:
    #         key - The String directory or filename.
    #         val - The Hash submap or the String contents of the file.
    # path - The String path of the page file. This may include the format
    #         extension in which case it will be ignored.
    #
    # Returns the Boolean response.
    def page_path_scheduled_for_deletion?(map, path)
      parts = path.split('/')
      if parts.size == 1
        deletions = map.keys.select { |k| !map[k] }
        downfile = parts.first.downcase.sub(/\.\w+$/, '')
        deletions.any? { |d| d.downcase.sub(/\.\w+$/, '') == downfile }
      else
        part = parts.shift
        if rest = map[part]
          page_path_scheduled_for_deletion?(rest, parts.join('/'))
        else
          false
        end
      end
    end

    # Determine if a given file is scheduled to be deleted in the next commit
    # for the given Index.
    #
    # map   - The Hash map:
    #         key - The String directory or filename.
    #         val - The Hash submap or the String contents of the file.
    # path - The String path of the file including extension.
    #
    # Returns the Boolean response.
    def file_path_scheduled_for_deletion?(map, path)
      parts = path.split('/')
      if parts.size == 1
        deletions = map.keys.select { |k| !map[k] }
        deletions.any? { |d| d == parts.first }
      else
        part = parts.shift
        if rest = map[part]
          file_path_scheduled_for_deletion?(rest, parts.join('/'))
        else
          false
        end
      end
    end

    # Proxies methods t
    def method_missing(name, *args)
      index.send(name, *args)
    end
  end
end
