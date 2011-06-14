# stdlib
require 'digest/md5'
require 'ostruct'

# external
require 'grit'
require 'github/markup'
require 'sanitize'

# internal
require 'stinker/git_access'
require 'stinker/committer'
require 'stinker/pagination'
require 'stinker/blob_entry'
require 'stinker/site'
require 'stinker/page'
require 'stinker/file'
require 'stinker/markup'
require 'stinker/albino'
require 'stinker/sanitization'

module Stinker
  VERSION = '0.0.1'

  class Error < StandardError; end

  class DuplicatePageError < Error
    attr_accessor :dir
    attr_accessor :existing_path
    attr_accessor :attempted_path

    def initialize(dir, existing, attempted, message = nil)
      @dir            = dir
      @existing_path  = existing
      @attempted_path = attempted
      super(message || "Cannot write #{@dir}/#{@attempted_path}, found #{@dir}/#{@existing_path}.")
    end
  end
end

