require "yard"
require "mustermann"

module YARD

  module Sinatra
    def self.routes
      YARD::Handlers::Sinatra::AbstractRouteHandler.routes
    end

    def self.error_handlers
      YARD::Handlers::Sinatra::AbstractRouteHandler.error_handlers
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

      def type 
        :method
      end

      def parameters
        return [] if caller[1] =~ /`signature'/
        @parameters
      end
    end
  end

  module Handlers

    # Displays Sinatra routes in YARD documentation.
    # Can also be used to parse routes from files without executing those files.
    module Sinatra

      # Logic both handlers have in common.
      module AbstractRouteHandler
        def self.uri_prefix
          uri_prefixes.join('')
        end
        def self.uri_prefixes
          @prefixes ||= []
        end
        def self.routes
          @routes ||= []
        end

        def self.error_handlers
          @error_handlers ||= []
        end

        def process
          case http_verb
          when 'NAMESPACE'
            AbstractRouteHandler.uri_prefixes << http_path(false)
            parse_sinatra_namespace(:scope => :class, :namespace => namespace)
            AbstractRouteHandler.uri_prefixes.pop
          when 'NOT_FOUND'
            register_error_handler(http_verb)
          else
            register_route(http_verb, http_path)
          end
        end

        def register_route(verb, path, doc = nil)
          # HACK: Removing some illegal letters.
          method_name = "" << verb << "_" << path.gsub(/[^\w_]/, "_")
          real_name   = "" << verb << " " << path

          params = []
          begin
            pattern = Mustermann.new(path)
            params = pattern.named_captures.keys.map{|v|[v]}
          rescue Mustermann::ParseError => e
            log.warn "Route parse error: #{e.message}" \
            "\n        in `#{statement.file}':#{statement.line}"
          end

          route = register CodeObjects::RouteObject.new(namespace, method_name, :instance) do |o|
            o.visibility = "public"
            o.source     = statement.source
            o.signature  = real_name
            o.explicit   = true
            o.scope      = scope
            o.http_verb  = verb
            o.http_path  = path
            o.real_name  = real_name
            o.parameters = params
            o.add_file(parser.file, statement.line)
            o.docstring  = statement.comments
          end


          AbstractRouteHandler.routes << route
          yield(route) if block_given?
        end

        def register_error_handler(verb, doc = nil)
          error_handler = register CodeObjects::RouteObject.new(namespace, verb, :instance) do |o|
            o.visibility = "public"
            o.source     = statement.source
            o.signature  = verb
            o.explicit   = true
            o.scope      = scope
            o.docstring  = statement.comments
            o.http_verb  = verb
            o.real_name  = verb
            o.add_file(parser.file, statement.line)
          end
          AbstractRouteHandler.error_handlers << error_handler
          yield(error_handler) if block_given?
        end
      end

      # Route handler for YARD's source parser.
      class RouteHandler < Ruby::Base
        include AbstractRouteHandler

        handles method_call(:get)
        handles method_call(:post)
        handles method_call(:put)
        handles method_call(:patch)
        handles method_call(:delete)
        handles method_call(:head)
        handles method_call(:not_found)
        handles method_call(:namespace)

        def http_verb
          statement.method_name(true).to_s.upcase
        end

        def http_path(include_prefix=true)
          path = statement.parameters.first
          path = path ? path.source : ''
          path = $1 if path =~ /['"](.*)['"]/
          include_prefix ? AbstractRouteHandler.uri_prefix + path : path
        end
        def parse_sinatra_namespace(opts={})
          parse_block(statement.last.last, opts)
        end
      end

      # Route handler for YARD's legacy parser.
      module Legacy
        class RouteHandler < Ruby::Legacy::Base
          include AbstractRouteHandler
          handles /\A(get|post|put|patch|delete|head|not_found|namespace)[\s\(].*/m

          def http_verb
            statement.tokens.first.text.upcase
          end

          def http_path(include_prefix=true)
            path = statement.tokens.find {|t| t.class == YARD::Parser::Ruby::Legacy::RubyToken::TkSTRING }
            path = path ? path.text : ''
            path = $1 if path =~ /^["'](.*)["']/
            include_prefix ? AbstractRouteHandler.uri_prefix + path : path
          end
          def parse_sinatra_namespace(opts={})
            parse_block(opts)
          end
        end
      end

    end
  end
end
