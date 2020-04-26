# frozen_string_literal: true

module Admission
  class Arbitration2

    VALID_DECISION = [ true, false, :forbidden, nil ].freeze
    FINAL_DECISION = [ true, :forbidden ].freeze
    ANY_ACTION = '*'.freeze

    attr_reader :person, :scope, :resource, :context

    def initialize ruleset, person, request, scope_or_resource=nil
      @scope, @resource = scope_and_resource scope_or_resource
      @rules = ruleset.rules_for self
      @person = person
      @request = request
      @context = nil
      @decisions = {}
    end

    def scope_and_resource scope
      case scope
        when Symbol, String
          [ scope.to_s ]
        when Array
          resource, nested_scope = scope
          [Admission.nested_scope(resource.class, nested_scope), resource]
        else
          [Admission.type_to_scope(scope.class), scope]
      end
    end

    def rule_on privilege
      unless privilege.context == @context
        @context = privilege.context
        @decisions.clear
      end
      return false if @rules.nil?
      get_decision(privilege).eql? true
    end

    def get_decision privilege
      return @decisions[privilege] if @decisions.key? privilege
      decision = decide privilege
      @decisions[privilege] = (decision.nil? ? false : decision)
    end

    def decide privilege
      rule = @rules[@request]
      decision = rule && apply_rule(rule, privilege)
      return decision if FINAL_DECISION.include? decision

      decision = decide_per_inheritance privilege
      return decision if FINAL_DECISION.include? decision

      rule = @rules[ANY_ACTION]
      rule && apply_rule(rule, privilege)
    end

    def decide_per_inheritance privilege
      inherited_decision = nil
      privilege.inherited&.each do |inherited|
        decision = get_decision inherited
        return decision if decision == :forbidden
        inherited_decision ||= decision
      end
      inherited_decision
    end

    def apply_rule rule, privilege
      decision = rule[privilege]

      if decision.respond_to? :apply_rule
        decision = decision.apply_rule self
      end

      unless VALID_DECISION.include? decision
        process_error 'invalid_decision', privilege, decision
        decision = false
      end

      decision
    end

    def process_error label, *details
      raise 'undefined yet'
    end

  end
end
