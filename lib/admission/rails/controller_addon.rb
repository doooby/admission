module Admission
  module Rails
    module ControllerAddon

      def self.included mod
        mod.extend ClassMethods
        mod.action_admission.for_all
      end

      module ClassMethods

        def action_admission
          @action_admission ||= ActionAdmission.new(self)
        end

      end

      private

      def request_admission! action, scope
        current_user.status.request! action, scope
      end

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