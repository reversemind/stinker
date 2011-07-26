require 'cgi'
require 'sinatra'
require 'stinker'
require 'stinker/frontend/app'

module MyPrecious
  class Adapter
    def self.build(type)
      app = Rack::Builder.new do
        use Rack::CommonLogger, $stderr
        use Rack::ShowExceptions
        run MyPrecious::App
      end.to_app
    end
  end
end
