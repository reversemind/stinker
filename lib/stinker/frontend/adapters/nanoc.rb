require 'nanoc3'

module MyPrecious
  module Adapters
    class Nanoc
      def self.build
        MyPrecious::App.set(:root_url, '/_stinker')
        autocompiler = Nanoc::Extra::AutoCompiler.new('.')
        app = Rack::Builder.new do
          use Rack::CommonLogger, $stderr
          use Rack::ShowExceptions
          map '/_stinker' do
            run MyPrecious::App
          end
          run autocompiler
        end.to_app
      end
    end
  end
end
