require 'cgi'

module MyPrecious
  module Views
    class Layout < Mustache
      include Rack::Utils
      alias_method :h, :escape_html

      attr_reader :name, :root_url

      def escaped_name
        CGI.escape(@name)
      end

      def title
        "Home"
      end

    end
  end
end
