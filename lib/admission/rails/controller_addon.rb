module Admission
  module Rails
    module ControllerAddon
      extend ActiveSupport::Concern

      included do
        action_admission.all_actions
      end

      class_methods do

        def action_admission
          @action_admission ||= ActionAdmission.new(self)
        end

      end

      private

      def request_admission! action, scope
        if ::Admission::Rails.log_access
          ::Admission::Rails.logger.info "Admission::Rails requesting `#{action}` over `#{scope}`"
        end

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