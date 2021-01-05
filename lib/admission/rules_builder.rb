module Admission
  class RulesBuilder
    CONDITION_REGEX = /^(?:if|unless)(?:_\w+)?$/

    attr_reader :rules

    def initialize privileges, &block
      @order = privileges
      @rules = []

      @modifiers_cache = {}
      instance_exec &block
    end

    def privilege name, grade=nil
      @privilege = @order.privilege_klass.produce_combined_name(name, grade)
      yield
      @privilege = nil
    end

    def allow *actions, **opts, &block
      actions = normalize_actions! opts[:any], opts[:actions], actions
      scope = normalize_scope! opts[:on]
      resource = normalize_resource! opts[:resource], opts[:on]
      rule = normalize_rule!(opts, block, resource) || true
      rule = cached_rule rule
      add_allowance_rule scope, actions.flatten, rule
    end

    def produce_index
      index = {}

      rules.each do |definition|
        privilege = definition[:privilege]
        rule = definition[:rule]
        scope = (index[definition[:scope]] ||= {})
        definition[:actions].each do |action|
          action_index = (scope[action] ||= {})
          action_index[privilege] = rule
        end
      end

      index.values.each do |h|
        h.values.each &:freeze
        h.freeze
      end
      index.freeze
    end

    private

    def add_allowance_rule scope, actions, rule
      raise 'must be called within `privilege` block' unless @privilege

      @rules << {
          privilege: @privilege,
          scope: scope,
          actions: actions,
          rule: rule
      }
    end

    def normalize_actions! is_any, action_opt, actions_list
      if action_opt
        actions_list = action_opt.is_a?(Array) ? action_opt : [action_opt]
      end
      if is_any
        raise 'catch-all :any options with actions list defined' unless actions_list.empty?
        return [Admission::ANY_ACTION]
      end
      validate_action_names! actions_list
      actions_list
    end

    def validate_action_names! actions
      if actions.include? Admission::ANY_ACTION
        raise "reserved action name #{Admission::ANY_ACTION}"
      end
      actions.each do |name|
        case name
          when String, Symbol then nil
          else raise "action must be a Symbol or String"
        end
      end
    end

    def normalize_scope! scope
      case scope
        when nil then Admission::NO_SCOPE
        when Symbol, String then scope.to_s
        when Array then Admission.nested_scope(*scope)
        when Class then Admission.type_to_scope scope
        else raise 'invalid scope'
      end
    end

    def normalize_resource! resource, scope
      return unless resource
      resource = (scope.is_a? Array) ? scope.first : scope
      if resource && !resource.is_a?(Class)
        raise "invalid resource type #{resource.to_s}"
      end
      resource
    end

    def normalize_rule! opts, block, resource
      conditions = opts.keys.select{|key| key.match? CONDITION_REGEX}

      if block
        raise 'block modifier combined with :if or :unless option' unless conditions.empty?
        return LambdaRule.new block, resource
      end

      unless conditions.empty?
        raise 'multiple :if or :unless options' if conditions.length > 1
        condition_key = conditions.first
        map_condition condition_key, opts[condition_key], resource
      end
    end

    def map_condition condition_key, rule, resource
      symbol_rule = rule.is_a? Symbol
      proc_rule = rule.is_a? Proc
      unless symbol_rule || proc_rule
        raise ':if and :unless conditions must be either Symbol or Proc'
      end

      _, operation, delegation = condition_key.match(/^(if|unless)(?:_(.+))?$/).to_a
      if delegation
        raise 'don\'t use proc for delegated condition' if proc_rule
        rule_class = case operation
          when 'if' then DelegatedMethodRule
          when 'unless' then NegativeDelegatedMethodRule
        end
        rule_class.new delegation, rule, resource

      else
        rule_class = case operation
          when 'if'
            proc_rule ? LambdaRule : MethodRule
          when 'unless'
            raise 'use :if instead :unless proc condition' if proc_rule
            NegativeMethodRule
        end
        rule_class.new rule, resource

      end
    end

    def cached_rule rule
      return rule unless rule.respond_to? :rule_id_array

      id = rule.rule_id_array
      cached = @modifiers_cache[id]
      unless cached
        @modifiers_cache[id] = rule
        cached = rule.freeze
      end
      cached
    end

  end

  class Rule

    def initialize resource
      @resource_klass = resource
    end

    def apply_rule privilege, resource
      apply privilege, (@resource_klass ? [resource] : [])
    end

    def rule_id_array
      [ self.class, @resource_klass ]
    end

  end

  class LambdaRule < Rule

    def initialize fn, resource
      super resource
      @fn = fn
    end

    def rule_id_array
      super + [ @fn ]
    end

    private

    def apply privilege, args
      privilege.instance_exec *args, &@fn
    end

  end

  class MethodRule < Rule

    def initialize name, resource
      super resource
      @name = name
    end

    def rule_id_array
      super + [ @name ]
    end

    private

    def apply privilege, args
      privilege.send @name, *args
    end

  end

  class NegativeMethodRule < MethodRule
    private

    def apply privilege, args
      not super
    end

  end

  class DelegatedMethodRule < Rule

    def initialize delegate_to, name, resource
      super resource
      @delegate_to = delegate_to
      @name = name
    end

    def rule_id_array
      super + [ @delegate_to, @name ]
    end

    private

    def apply privilege, args
      target = privilege.send @delegate_to
      target.send @name, *args
    end

  end

  class NegativeDelegatedMethodRule < DelegatedMethodRule
    private

    def apply privilege, args
      not super
    end

  end

end
