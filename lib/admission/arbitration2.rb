# frozen_string_literal: true

module Admission
  class Arbitration2

    attr_reader :action, :scope, :resource

    def initialize order, rules_index, action, scope_or_resource
      @order = order

      @action = action
      parse_scope scope_or_resource

      rules = rules_index[@scope]
      @action_rules = rules[action]
      @any_action_rules = rules[Admission::ANY_ACTION]
    end

    def decide_on privilege
      make_a_decision_on(privilege.name, privilege)
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

    def make_a_decision_on privilege_name, original_privilege
      decision = decide_per_top_grade_rule privilege_name, original_privilege
      return decision unless decision.nil?

      decision = decide_per_any_action_rule privilege_name, original_privilege
      return decision unless decision.nil?

      decide_per_inherited_rules privilege_name, original_privilege
    end

    def decide_per_top_grade_rule privilege_name, original_privilege
      return unless @action_rules

      rule = nil
      @order.top_down_grades_for(privilege_name).first do |grade_name|
        rule = @action_rules[grade_name]
      end

      if rule.respond_to? :apply_rule
        rule = rule.apply_rule original_privilege, resource
        rule = false if rule.nil?
      end
      rule
    end

    def decide_per_any_action_rule privilege_name, original_privilege
      return unless @any_action_rules
      rule = @any_action_rules[privilege_name]
      rule = rule.apply_rule original_privilege, resource if rule.respond_to? :apply_rule
      rule
    end

    def decide_per_inherited_rules privilege_name, original_privilege
      @order.inheritance_list_for(privilege_name).each do |inherited_name|
        decision = make_a_decision_on inherited_name, original_privilege
        return decision if decision
      end
    end

    # def decide_per_inheritance privilege
    #   inherited_decision = nil
    #   privilege.inherited&.each do |inherited|
    #     decision = decide inherited
    #     return decision if decision == :forbidden
    #     inherited_decision ||= decision
    #   end
    #   inherited_decision
    # end

  end
end
