module Admission
  module Rails
    class ScopeResolver

      def initialize scope
        @getter = scope
        freeze
      end

      def apply controller_instance
        scope = case @getter
          when Symbol
            controller_instance.send @getter

          when Proc
            controller_instance.instance_exec &@getter

          else # void

        end

        yield scope if scope
      end

      def self.void
        @void ||= new(nil)
      end

      def self.default
        @default ||= new(-> {
          controller_name.to_sym
        })
      end

      def self.using scope_resolver
        return scope_resolver if scope_resolver.is_a? ScopeResolver

        unless scope_resolver.is_a?(Proc) || scope_resolver.is_a?(Symbol)
          raise 'Function to resolve the admission scope needed.'+
              ' Pass a block or `resolve_to:` parameter.'
        end

        new scope_resolver
      end

    end
  end
end