module Admission
  module Rails
    class ActionAdmission

      ALL_ACTIONS = '^'.freeze

      attr_reader :controller, :resolvers

      def initialize controller
        @controller = controller
        @resolvers = {}
      end

      # config methods (adding resolvers)

      def for *actions, resolve_to: nil, &block
        resolve_to = resolve_to || block
        resolver = ScopeResolver.using resolve_to

        set_resolver actions, resolver
      end

      def for_all resolve_to=nil, &block
        self.for ALL_ACTIONS, resolve_to: (resolve_to || block || ScopeResolver.default)
      end

      def for_resource *actions, all: false, nested: false
        finder_name = if nested
          "#{controller.controller_name}_admission_scope"
        else
          "find_#{controller.controller_name.singularize}"
        end
        resolver = ScopeResolver.using finder_name.to_sym

        actions = all ? ALL_ACTIONS : actions
        set_resolver actions, resolver
      end

      def skip *actions
        set_resolver actions, ScopeResolver.void
      end

      # run-time
      def scope_for_action action
        resolvers[action] ||
            resolvers[ALL_ACTIONS] ||
            parent&.scope_for_action(action)
      end

      private

      def parent
        klass = @controller.superclass
        if klass.respond_to? :action_admission
          klass.action_admission
        end
      end

      def set_resolver actions, resolver
        if actions.is_a? Array
          actions.flatten.compact.map(&:to_s).each do |action|
            resolvers[action] = resolver
          end

        else
          resolvers[actions.to_s] = resolver

        end
      end

    end
  end
end