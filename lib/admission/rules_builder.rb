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
      actions = normalize_actions! opts[:actions] || actions
      scope = normalize_scope! opts[:on]
      resource = normalize_resource! opts[:resource], opts[:on]
      rule = normalize_rule!(opts, block) || true
      rule = cached_rule rule, resource
      add_allowance_rule scope, actions, rule
    end

    def disallow *actions, **opts
      actions = normalize_actions! actions
      scope = normalize_scope! opts[:on]
      add_allowance_rule scope, actions, false
    end

    def allow_on scope, *actions, **opts, &block
      opts[:on] = scope
      allow *actions, **opts, &block
    end

    def allow_on_resource resource, *actions, **opts, &block
      opts[:on] = resource
      opts[:resource] = true
      allow *actions, **opts, &block
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

    def normalize_actions! actions
      actions = [actions] unless actions.is_a? Array
      actions.flatten!
      validate_action_names! actions
      actions.map!(&:to_s)
      actions
    end

    def validate_action_names! actions
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
        when Class then Admission.resource_type_to_scope scope
        else raise 'invalid scope'
      end
    end

    def normalize_resource! is_resource, scope
      return unless is_resource
      resource = (scope.is_a? Array) ? scope.first : scope
      raise "invalid resource type #{resource.to_s}" unless resource.is_a?(Class)
      resource
    end

    def normalize_rule! opts, block
      conditions = opts.keys.select{|key| key.match? CONDITION_REGEX}

      if block
        raise 'block modifier combined with :if or :unless option' unless conditions.empty?
        return LambdaRule.new block
      end

      unless conditions.empty?
        raise 'multiple :if or :unless options' if conditions.length > 1
        condition_key = conditions.first
        map_condition condition_key, opts[condition_key]
      end
    end

    def map_condition condition_key, rule
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
        rule_class.new delegation, rule

      else
        rule_class = case operation
          when 'if'
            proc_rule ? LambdaRule : MethodRule
          when 'unless'
            raise 'use :if instead :unless proc condition' if proc_rule
            NegativeMethodRule
        end
        rule_class.new rule

      end
    end

    def cached_rule rule, resource
      return rule unless rule.respond_to? :rule_id_array

      id = rule.rule_id_array resource
      cached = @modifiers_cache[id]
      unless cached
        @modifiers_cache[id] = rule
        rule.requires_resource = !!resource
        cached = rule.freeze
      end
      cached
    end

  end

  class Rule
    attr_accessor :requires_resource

    def apply_rule privilege, resource
      args = if requires_resource
        return false if resource.nil?
        [ resource ]
      else
        []
      end
      apply privilege, args
    end

    def rule_id_array resource
      [ self.class, resource ]
    end

  end

  class LambdaRule < Rule

    def initialize fn
      @fn = fn
    end

    def rule_id_array _
      super + [ @fn ]
    end

    private

    def apply privilege, args
      privilege.instance_exec *args, &@fn
    end

  end

  class MethodRule < Rule

    def initialize name
      @name = name
    end

    def rule_id_array _
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

    def initialize delegate_to, name
      @delegate_to = delegate_to
      @name = name
    end

    def rule_id_array _
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