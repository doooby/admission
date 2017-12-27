module Admission
  module Rails
    class ActionAdmission

      ALL_ACTIONS = '^'.freeze

      attr_reader :controller, :resolvers, :attached

      def initialize controller
        @controller = controller
        @resolvers = {}
      end

      # config methods (adding resolvers)

      def for *actions, resolve_to: nil, &block
        actions = actions.flatten.compact.map &:to_s
        resolve_to = resolve_to || block
        resolver = ScopeResolver.using resolve_to

        set_resolver actions, resolver
      end

      def for_all resolve_to=nil, &block
        self.for ALL_ACTIONS, resolve_to: (resolve_to || block || ScopeResolver.default)
      end

      def for_resource *actions, all: false, nested: false
        actions = if all
          ALL_ACTIONS
        else
          actions.flatten.compact.map &:to_s
        end

        finder_name = if nested
          "#{controller.controller_name}_admission_scope"
        else
          "find_#{controller.controller_name.singularize}"
        end
        resolver = ScopeResolver.using finder_name.to_sym

        set_resolver actions, resolver
      end

      def skip *actions
        actions = actions.flatten.compact.map &:to_s

        set_resolver actions, ScopeResolver.void
      end

      # # attaching / detaching controller's before action
      #
      # def attach_before_action
      #   if already_attached?
      #     raise ::Admission::ConfigError.new(
      #         "Controller callback to assure admission has already been attached for `#{@controller.name}` or parent."
      #     )
      #   end
      #
      #   @controller.before_action :assure_admission
      #   @attached = true
      # end
      #
      # def reorder_before_action
      #   if attached
      #     raise ::Admission::ConfigError.new(
      #         "Controller callback to assure admission has already been re-attached for `#{@controller.name}`"
      #     )
      #   end
      #
      #   @controller.skip_before_action :assure_admission
      #   @controller.before_action :assure_admission
      #   @attached = true
      # end
      #
      # def skip_before_action
      #   @controller.skip_before_action :assure_admission
      #   @attached = false
      # end

      # run-time

      def scope_for_action action
        resolvers[action] ||
            resolvers[ALL_ACTIONS] ||
            parent&.scope_for_action(action)
      end

      # protected
      #
      # def already_attached?
      #   attached || parent&.already_attached?
      # end

      private

      def parent
        klass = @controller.superclass
        if klass.respond_to? :action_admission
          klass.action_admission
        end
      end

      def set_resolver actions, resolver
        if actions.is_a? Array
          actions.each do |action|
            resolvers[action] = resolver
          end

        else
          resolvers[actions] = resolver

        end
      end

    end
  end
end