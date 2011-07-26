# stdlib
require 'digest/md5'
require 'ostruct'
require 'yaml'

# external
require 'grit'
require 'github/markup'
require 'sanitize'

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end


# internal
require_relative 'stinker/git_access'
require_relative 'stinker/committer'
require_relative 'stinker/pagination'
require_relative 'stinker/blob_entry'
require_relative 'stinker/site'
require_relative 'stinker/page'
require_relative 'stinker/file'
require_relative 'stinker/markup'
require_relative 'stinker/albino'
require_relative 'stinker/sanitization'

module Stinker
  VERSION = '0.0.4'

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

