module Admission
  module Rails
    module ControllerAddon

      def self.included controller
        controller.extend ClassMethods
        controller.before_action :assure_admission
      end

      module ClassMethods

        # `action_admission` defines your configuration of admission scopes for actions.
        # By default, scope is the controller's name, which should be good starting point,
        # but you can change it to what ever suits you; and for resources you need
        # to set it explicitly.
        #
        # For all options see `Admission::Rails::ActionAdmission`
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
      # see ActionAdmission#invoke!
      def assure_admission
        self.class.action_admission.invoke! self
      end

    end
  end
end