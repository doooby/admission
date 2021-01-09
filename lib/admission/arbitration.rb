# frozen_string_literal: true

module Admission
  class Arbitration

    attr_reader :order, :rules_index
    attr_reader :action, :scope, :resource, :result

    def initialize order, rules_index, action, scope_or_resource
      @order = order
      @rules_index = rules_index

      @action = action.to_s
      parse_scope scope_or_resource
      scope_rules = @rules_index[@scope]
      @action_rules = scope_rules && scope_rules[@action]
      @result = nil
    end

    def inspect
      attrs_list = [
          "action=#{action}",
          "scope=#{scope}",
      ]
      if resource
        resource_text = if resource.respond_to? :id
          "resource=<#{resource.class.name} id=#{resource.id}>"
        else
          "resource=<#{resource.class.name}>"
        end
        attrs_list.push resource_text
      end
      "<#{self.class} #{attrs_list.join ' '}>"
    end
    alias to_s inspect

    def case_to_s
      "Admission denied for action :#{@action} on :#{@scope}"
    end

    def process status
      if Admission.debug_arbitration
        instance_exec status, &Admission.debug_arbitration
      end
      @result = status.privileges.any? do |privilege|
        decide_on privilege
      end
    end

    def decide_on privilege
      decision = rule privilege.name
      if decision.respond_to? :apply_rule
        decision = decision.apply_rule privilege, resource
      end
      decision.nil? ? false : decision
    end

    private

    def parse_scope scope
      case scope
        when Symbol, String
          @scope = scope.to_s

        when Array
          resource, nested_scope = scope
          @scope = Admission.nested_scope resource.class, nested_scope
          @resource = resource

        else
          @scope = Admission.resource_type_to_scope scope.class
          @resource = scope

      end
    end

    def rule privilege_name
      decision = rule_per_privilege privilege_name
      return decision unless decision.nil?

      rule_per_inheritance privilege_name
    end

    def rule_per_privilege privilege_name
      return unless @action_rules

      order.top_down_grades_for(privilege_name).each do |grade_name|
        decision = @action_rules[grade_name]
        return decision unless decision.nil?
      end

      nil
    end

    def rule_per_inheritance privilege_name
      order.inheritance_list_for(privilege_name).each do |inherited_name|
        decision = rule inherited_name
        return decision unless decision.nil?
      end

      nil
    end

  end
end
