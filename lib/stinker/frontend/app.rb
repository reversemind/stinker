require 'cgi'
require 'sinatra'
require 'stinker'
require 'mustache/sinatra'

require 'stinker/frontend/views/layout'
require 'stinker/frontend/views/editable'

module MyPrecious
  class App < Sinatra::Base
    register Mustache::Sinatra

    dir = File.dirname(File.expand_path(__FILE__))

    # We want to serve public assets for now

    set :public,    "#{dir}/public"
    set :static,    true
    set :root_url, ''

    set :mustache, {
      # Tell mustache where the Views constant lives
      :namespace => MyPrecious,

      # Mustache templates live here
      :templates => "#{dir}/templates",

      # Tell mustache where the views are
      :views => "#{dir}/views"
    }

    # Sinatra error handling
    configure :development, :staging do
      enable :show_exceptions, :dump_errors
      disable :raise_errors, :clean_trace
    end

    configure :test do
      enable :logging, :raise_errors, :dump_errors
    end

    before do
      @root_url = settings.root_url
    end

    get '/' do
      redirect @root_url + '/pages'
    end

    get '/edit/*' do
      @name = params[:splat].first
      @site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      if page = @site.page(@name)
        @page = page
        @meta = page.meta_data
        @content = page.raw_text_data
        mustache :edit
      else
        mustache :create
      end
    end

    post '/edit/*' do
      site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      page = site.page(params[:splat].first)
      name = params[:page_name] || page.name || params[:page_title]
      committer = Stinker::Committer.new(site, commit_message)
      commit    = {:committer => committer}
      meta = {'title' => params[:page_title]}

      meta.merge!(params[:extras]) if params[:extras]

      update_site_page(site, page, params[:content], commit, meta, name,
        params[:format])
      committer.commit

      redirect @root_url + "/"
    end

    post '/create' do
      name = params[:page]
      site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)

      format = params[:format].intern

      begin
        site.write_page(name, format, params[:content], commit_message)
        redirect @root_url + "/#{CGI.escape(name)}"
      rescue Stinker::DuplicatePageError => e
        @message = "Duplicate page: #{e.message}"
        mustache :error
      end
    end

    post '/revert/:page/*' do
      site  = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      @name = params[:page]
      @page = site.page(@name)
      shas  = params[:splat].first.split("/")
      sha1  = shas.shift
      sha2  = shas.shift

      if site.revert_page(@page, sha1, sha2, commit_message)
        redirect @root_url + "/#{CGI.escape(@name)}"
      else
        sha2, sha1 = sha1, "#{sha1}^" if !sha2
        @versions = [sha1, sha2]
        diffs     = site.repo.diff(@versions.first, @versions.last, @page.path)
        @diff     = diffs.first
        @message  = "The patch does not apply."
        mustache :compare
      end
    end

    post '/preview' do
      site     = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      @name    = "Preview"
      @page    = site.preview_page(@name, params[:content], params[:format])
      @content = @page.formatted_data
      mustache :page
    end

    get '/history/:name' do
      @name     = params[:name]
      site      = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      @page     = site.page(@name)
      @page_num = [params[:page].to_i, 1].max
      @versions = @page.versions :page => @page_num
      mustache :history
    end

    post '/compare/:name' do
      @versions = params[:versions] || []
      if @versions.size < 2
        redirect @root_url + "/history/#{CGI.escape(params[:name])}"
      else
        redirect @root_url +  "/compare/%s/%s...%s" % [
          CGI.escape(params[:name]),
          @versions.last,
          @versions.first]
      end
    end

    get '/compare/:name/:version_list' do
      @name     = params[:name]
      @versions = params[:version_list].split(/\.{2,3}/)
      site      = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      @page     = site.page(@name)
      diffs     = site.repo.diff(@versions.first, @versions.last, @page.path)
      @diff     = diffs.first
      mustache :compare
    end

    get %r{^/(javascript|css|images)} do
      halt 404
    end

    get %r{/(.+?)/([0-9a-f]{40})} do
      name = params[:captures][0]
      site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      if page = site.page(name, params[:captures][1])
        @page = page
        @name = name
        @content = page.formatted_data
        mustache :page
      else
        halt 404
      end
    end

    get '/search' do
      @query = params[:q]
      site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      @results = site.search @query
      @name = @query
      mustache :search
    end

    get '/pages' do
      site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      @results = site.pages
      @ref = site.ref
      mustache :pages
    end

    get '/*' do
      show_page_or_file(params[:splat].first)
    end

    def show_page_or_file(name)
      @site = Stinker::Site.new(settings.stinker_path, settings.wiki_options)
      if page = @site.page(name)
        name = name =~ /^[Ii]ndex/ ? "" : name
        redirect '/'+name +'/'
      elsif file = @site.file(name)
        content_type file.mime_type
        file.raw_data
      else
        @name = name
        mustache :create
      end
    end

    def update_site_page(site, page, content, commit_message, meta = {}, name = nil, format = nil)
      return if !page ||  
        ((!content || page.raw_data == content) && page.format == format)
      name    ||= page.name
      format    = (format || page.format).to_sym
      meta ||= page.meta_data
      content ||= page.raw_text_data
      site.update_page_with_meta(page, name, format, content.to_s, meta, commit_message)
    end

    def commit_message
      { :message => params[:message] }
    end
  end
end

