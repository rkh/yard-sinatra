require "yard"

module YARD

  module Sinatra
    # Plugin options
    #
    # Available options:
    # * `enable-outside-sinatra-base`: Allow processing to happen even outside of
    #   namespaces descending from Sinatra::Base
    # * `enable-unknown-namespaces`: Allow processing with namespaced method
    #   calls (e.g. SomeClass.get), even when those cannot be confirmed to
    #   descend from Sinatra::Base
    # * `enable-instance-methods`: Allow processing of calls made from within
    #   instance methods.
    # * `enable-all`: Do not limit processing at all
    def self.options
      @options ||= YARD::Config.options['yard-sinatra'] || {}
    end

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

        def options
          YARD::Sinatra.options
        end

        def check_outside_sinatra_base_pass(ns = namespace)
          return true if options['enable-outside-sinatra-base']
          ns.inheritance_tree.map(&:to_s).include? 'Sinatra::Base'
        end

        def check_unknown_namespace_pass
          return true if options['enable-unknown-namespaces'] ||
                         statement.namespace.nil? ||
                         statement.namespace.source == 'self'
          ns = Registry.resolve(namespace, statement.namespace.source, true)
          return false if ns.nil? # Could not resolve namespace
          check_outside_sinatra_base_pass(ns)
        end

        def check_instance_method_pass
          return true if options['enable-instance-methods']
          !(owner.type == :method && owner.scope == :instance)
        end

        def process
          unless options['enable-all']
            return unless check_outside_sinatra_base_pass
            return unless check_unknown_namespace_pass
            return unless check_instance_method_pass
          end

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
