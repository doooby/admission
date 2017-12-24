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

      def all_actions resolve_to: nil, &block
        resolve_to = resolve_to || block
        resolver = if resolve_to
          ScopeResolver.using resolve_to
        else
          ScopeResolver.default
        end

        set_resolver ALL_ACTIONS, resolver
      end

      def skip only: nil
        only = only && [only].flatten.map(&:to_s)
        actions = if only && !only.empty?
          only
        else
          ALL_ACTIONS
        end

        set_resolver actions, ScopeResolver.void
      end

      def actions *actions, resolve_to: nil, &block
        actions = actions.flatten.compact.map &:to_s
        resolve_to = resolve_to || block
        resolver = ScopeResolver.using resolve_to

        set_resolver actions, resolver
      end

      def actions_to_resource *actions, all: false
        actions = if all
          ALL_ACTIONS
        else
          actions.flatten.compact.map &:to_s
        end

        finder_name = "find_#{controller.controller_name.singularize}".to_sym
        resolver = ScopeResolver.using finder_name

        set_resolver actions, resolver
      end

      def actions_to_nested_resource *actions, all: false
        actions = if all
          ALL_ACTIONS
        else
          actions.flatten.compact.map &:to_s
        end

        finder_name = "#{controller.controller_name}_admission_scope".to_sym
        resolver = ScopeResolver.using finder_name

        set_resolver actions, resolver
      end

      def attach_before_action
        if @attached
          raise ::Admission::ConfigError.new(
              "Controller callback to assure admission has already been attached for `#{@controller.name}`"
          )
        end

        @controller.skip_before_action :assure_admission
        @controller.before_action :assure_admission
        @attached = true
      end

      # run-time

      def scope_for_action action
        resolvers[action] ||
            resolvers[ALL_ACTIONS] ||
            parent.try(:scope_for_action, action)
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