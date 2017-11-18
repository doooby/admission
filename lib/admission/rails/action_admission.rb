module Admission
  module Rails
    class ActionAdmission

      ALL_ACTIONS = '^'.freeze

      attr_reader :controller, :resolvers

      def initialize controller
        @controller = controller
        @resolvers = {}
      end

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

      def actions *list, resolve_to: nil, &block
        list = list.flatten.compact.map(&:to_s)
        resolve_to = resolve_to || block
        resolver = ScopeResolver.using resolve_to

        set_resolver list, resolver
      end

      def resolve_to_resource *list
        list = list.flatten.compact.map(&:to_s)
        finder_name = "find_#{controller.controller_name.singularize}".to_sym
        ScopeResolver.using finder_name

        set_resolver list, resolver
      end

      def attach_before_action reorder: false
        raise 'already attached' if @attached

        @controller.skip_before_action :_assure_admission if reorder
        @controller.before_action :_assure_admission
        @attached = true
      end

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