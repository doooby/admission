module Admission
  module Rails
    module ControllerAddon

      def self.included controller
        controller.extend ClassMethods
        controller.before_action :assure_admission
        controller.action_admission.for_all
      end

      module ClassMethods

        # `action_admission` defines your configuration of admission scopes for actions.
        # By default, scope is the controller's name, which should be good starting point,
        # but you can change it to what ever suits you; and for resources you need
        # to set it explicitly.
        #
        # For all options see `Admission::Rails::ActionAdmission`
        #
        # `action_admission` is inherently passed to child controllers,
        # so be aware that setting some scope for an action in a parent controller
        # will result to the action being resolved to the same scope in child controller.
        # On the other hand setting defaults in ApplicationController will set you up
        # to ensure that every child controller is under admission control.
        def action_admission
          @action_admission ||= ActionAdmission.new(self)
        end

      end

      private

      # This is just a helper to proxy the admission request to the user
      # you may need to redefine it if `current_user` is not the right accessor
      def request_admission! action, scope
        current_user.status.request! action, scope
      end

      # The default callback method that assures the admission request.
      # It is included automatically if you include `Admission::Rails::ControllerAddon`.
      #
      # `#action_admission` is used to get the scope for the action (`#action_name`).
      def assure_admission
        action = action_name
        scope_resolver = self.class.action_admission.scope_for_action action

        unless scope_resolver
          raise ScopeNotDefined.new(self)
        end

        scope_resolver.apply self do |scope|
          request_admission! action.to_sym, scope
        end
      end

    end
  end
end