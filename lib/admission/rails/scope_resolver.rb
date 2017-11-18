module Admission
  module Rails
    class ScopeResolver

      def initialize scope
        @scope = scope
        freeze
      end

      def apply controller_instance
        case @scope
          when Symbol
            yield controller_instance.send(@scope)

          when Proc
            yield controller_instance.instance_exec(&@scope)

          else
            # void
        end
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

        raise ArgumentError.new(
            'Function to resolve the admission scope needed.'+
                ' Pass a block or `resolve_to:` parameter.'
        ) unless scope_resolver.is_a?(Proc) || scope_resolver.is_a?(Symbol)

        new scope_resolver
      end

    end
  end
end