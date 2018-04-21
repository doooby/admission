module Admission
  module Rails
    class ActionAdmission

      ALL_ACTIONS = '^'.freeze

      attr_reader :controller, :resolvers

      def initialize controller
        @controller = controller
        @resolvers = {}
      end

      # Sets `action_admission` to be resolved to given scope for particular actions.
      #
      #   action_admission.for :show, :edit, resolve_to: :find_record
      #   action_admission.for %i[show edit], resolve_to: :find_record
      #
      #   action_admission.for :show, resolve_to: :method_that_returns_the_scope
      #   action_admission.for :show, resolve_to: ->{ 'the_scope' }
      #   action_admission.for(:show){ 'the_scope' }
      #
      def for *actions, resolve_to: nil, &block
        resolve_to = resolve_to || block
        resolver = ScopeResolver.using resolve_to

        set_resolver actions, resolver
      end

      # Sets `action_admission` to be resolved to given scope for all actions.
      #
      #   action_admission.for_all :method_that_returns_the_scope
      #   action_admission.for_all ->{ 'the_scope' }
      #   action_admission.for_all{ 'the_scope' }
      #
      def for_all resolve_to=nil, &block
        self.for ALL_ACTIONS, resolve_to: (resolve_to || block || ScopeResolver.default)
      end

      # Sets `action_admission` to be resolved to default scope for particular actions.
      # i.e. this is the means to reset to default functionality.
      #
      #   action_admission.default_for :show, :edit
      #   action_admission.default_for %i[show edit]
      #
      def default_for *actions
        set_resolver actions, ScopeResolver.default
      end

      # Sets `action_admission` to be resolved to resource scope for particular actions.
      # Resource scope is just a resource instance (or nested resource) which is load
      # in method with predefined standard name. for example:
      #
      #   class PeopleController
      #     action_admission.resource_for :show
      #
      #     # scope is `:people`, with resource `@person`
      #     # i.e. defined rule: `allow_resource(Person, %i[show]`){|person| # ... }
      #     def find_person
      #       @person = Person.find params[:id]
      #     end
      #   end
      #
      #   class PropertiesController
      #     action_admission.resource_for :show, nested: true
      #
      #     # scope is `:'people-properties'` with resource `@person`
      #     # i.e. defined rule: `allow_resource([Person, :properties], %i[show]`){|person| # ... }
      #     def properties_admission_scope
      #       @property = Property.find params[:id]
      #       @person = @property.owner
      #       [@person, controller_name.to_sym]
      #     end
      #   end
      #
      def resource_for *actions, all: false, nested: false
        finder_name = if nested
          "#{controller.controller_name}_admission_scope"
        else
          "find_#{controller.controller_name.singularize}"
        end
        resolver = ScopeResolver.using finder_name.to_sym

        actions = all ? ALL_ACTIONS : actions
        set_resolver actions, resolver
      end
      def for_resource *as, **ks
        warn '`ActionAdmission#for_resource` is deprecated method name, use `#resource_for`.'
        resource_for *as, **ks
      end

      # Sets `action_admission` to be ignored for given actions.
      # Useful when you have `action_admission` included inherently.
      # Or for when you are brave enough to check the admission on your own
      # within the action (though you should rather never need to do that).
      #
      #   action_admission.skip :homepage, :news_feed
      #   action_admission.skip %i[homepage news_feed]
      #
      def skip *actions
        set_resolver actions, ScopeResolver.void
      end

      # run-time means to find the scope resolver for the action
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