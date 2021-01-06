# frozen_string_literal: true

module Admission
  class Arbitration2

    attr_reader :action, :scope, :resource
    attr_reader :order, :rules_index

    def initialize order, rules_index, action, scope_or_resource
      @order = order
      @rules_index = rules_index

      @action = action
      parse_scope scope_or_resource
      @action_rules = rules_index[@scope][action]
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
          @scope = Admission.type_to_scope scope.class, scope

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
