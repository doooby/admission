module Admission
  module Rails
    class ScopeNotDefined < ::StandardError

      attr_reader :controller

      def initialize controller
        @controller = controller
      end

      def action
        "#{controller.class.name}##{controller.action_name}"
      end

      def message
        "Undefined scope to resolve admission to. Requested action: #{action}."
      end

    end
  end
end