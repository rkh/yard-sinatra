require "yard"

module YARD

  module Sinatra
    def self.routes
      YARD::Handlers::Sinatra::AbstractRouteHandler.routes
    end
  end

  module CodeObjects
    class RouteObject < MethodObject
      attr_accessor :http_verb, :http_path, :real_name

      def name(prefix = false)
        return super unless show_real_name?
        prefix ? (sep == ISEP ? "#{sep}#{real_name}" : real_name.to_s) : real_name.to_sym
      end

      # @see YARD::Handlers::Sinatra::AbstractRouteHandler#register_route
      # @see #name
      def show_real_name?
        real_name and caller[1] =~ /`signature'/
      end
    end
  end

  module Handlers

    # Displays Sinatra routes in YARD documentation.
    # Can also be used to parse routes from files without executing those files.
    module Sinatra

      # Logic both handlers have in common.
      module AbstractRouteHandler
        def self.routes
          @routes ||= []
        end

        def process
          path = http_path
          path = $1 if path =~ /^"(.*)"$/
          register_route(http_verb, path)
          register_route('HEAD', path) if http_verb == 'GET'
        end

        def register_route(verb, path, doc = nil)
          # HACK: Removing some illegal letters.
          method_name = "" << verb << "_" << path.gsub(/[^\w_]/, "_")
          real_name   = "" << verb << " " << path
          route = register CodeObjects::RouteObject.new(namespace, method_name, :instance) do |o|
            o.visibility = "public"
            o.source     = statement.source
            o.signature  = real_name
            o.explicit   = true
            o.scope      = scope
            o.docstring  = statement.comments
            o.http_verb  = verb
            o.http_path  = path
            o.real_name  = real_name
            o.add_file(parser.file, statement.line)
          end
          AbstractRouteHandler.routes << route
          yield(route) if block_given?
        end
      end

      # Route handler for YARD's source parser.
      class RouteHandler < Ruby::Base
        include AbstractRouteHandler

        handles method_call(:get)
        handles method_call(:post)
        handles method_call(:put)
        handles method_call(:delete)
        handles method_call(:head)

        def http_verb
          statement.method_name(true).to_s.upcase
        end

        def http_path
          statement.parameters.first.source
        end
      end

      # Route handler for YARD's legacy parser.
      module Legacy
        class RouteHandler < Ruby::Legacy::Base
          include AbstractRouteHandler
          handles /\A(get|post|put|delete|head)[\s\(].*/m

          def http_verb
            statement.tokens.first.text.upcase
          end

          def http_path
            statement.tokens[2].text
          end
        end
      end

    end
  end
end
