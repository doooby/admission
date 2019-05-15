module Admission
  module Rails
    class ActionAdmission

      ALL_ACTIONS = '^'.freeze

      attr_reader :controller, :before_helpers, :resolvers

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
        self.for ALL_ACTIONS, resolve_to: (resolve_to || block)
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

      # Adds a callback that is applied before mandatory admission request
      # can be filter per actions using options `only` and `except`
      #
      #   action_admission.before_helper :helper_method, only: :some_action
      #   action_admission.before_helper ->{ do_something }, only: [:some_action]
      #   action_admission.before_helper(except: %i[this and_this]){ do_something }
      #
      def before_helper helper=nil, only: nil, except: nil, &block_helper
        only = [*only].flatten.compact
        only = nil if only.empty?
        except = [*except].flatten.compact
        except = nil if except.empty?
        (@before_helpers ||= []).push(
            BeforeHelper.new (block_helper || helper), only, except
        )
      end

      # this is the run-time means to resolve admission:
      # - it finds the scope for given action
      # - it applies all before helpers
      # - it request admission per action and scope
      def invoke! controller_instance
        action = controller_instance.action_name
        scope_resolver = scope_for_action action

        scope_resolver.apply controller_instance do |scope|
          action = action.to_sym

          before_helpers && before_helpers.each do |helper|
            helper.apply controller_instance if helper.applicable? action
          end

          controller_instance.send :request_admission!, action, scope
        end
      end

      private

      def set_resolver actions, resolver
        if actions.is_a? Array
          actions.flatten.compact.map(&:to_s).each do |action|
            resolvers[action] = resolver
          end

        else
          resolvers[actions.to_s] = resolver

        end
      end

      def scope_for_action action
        resolvers[action] ||
            resolvers[ALL_ACTIONS] ||
            ScopeResolver.default
      end

    end

    class BeforeHelper

      def initialize helper, only, except
        @helper = case helper
          when Proc, Symbol then helper
          else raise 'bad usage - give either callable or symbol for method name'
        end

        @only = only
        @except = except
      end

      def applicable? action
        (@only ? @only.include?(action) : true) &&
            (@except ? !@except.include?(action) : true)
      end

      def apply controller
        case @helper
          when Proc
            controller.instance_exec &@helper
          when Symbol
            controller.send @helper
        end
      end

    end

  end
end