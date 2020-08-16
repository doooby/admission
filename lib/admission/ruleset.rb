class Ruleset

  def initialize builder
    @index = create_index builder
  end

  def rules_for arbitration
    rules = @index[arbitration.scope]
    arbitration.process_error 'no_rules' unless rules
    rules
  end

  private

  def create_index builder
    index = {}

    builder.rules.each do |privilege:, scope:, actions:, rule:|
      scope = (index[scope] ||= {})
      actions.each do |action|
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

  class Builder

    attr_reader :rules

    def initialize privileges, &block
      @order = privileges
      @rules = []

      @modifiers_cache = {}
      instance_exec &block
      @modifiers_cache = nil
    end

    def privilege name, level=nil
      @privilege = @order.get name, level
      unless @privilege
        raise 'no such privilege: %s%s%s' % [
            name,
            Admission::Privilege::SEPARATOR,
            level
        ]
      end
      yield
      @privilege = nil
    end

    def allow scope, *actions, **opts, &block
      scope = normalize_scope! scope
      actions = opts[:actions] if opts.key? :actions
      validate_action_names! actions

      if opts[:resource].eql? true
        opts[:resource] = (scope.is_a? Array) ? scope.first : scope
      end

      modifier = RuleModifier.create! @modifiers_cache, opts, opts[:if] || block
      add_allowance_rule scope, actions.flatten, modifier
    end

    def allow_resource resource, *actions, **opts, &block
      opts[:resource] = true
      allow resource, *actions, **opts, &block
    end

    def allow_any scope, **opts, &block
      scope = normalize_scope! scope
      any_actions = [ Admission::Arbitration2::ANY_ACTION ]

      if opts[:resource].eql? true
        opts[:resource] = (scope.is_a? Array) ? scope.first : scope
      end

      modifier = RuleModifier.create! @modifiers_cache, opts, opts[:if] || block
      add_allowance_rule scope, any_actions, modifier
    end

    def forbid scope, *actions
      scope = normalize_scope! scope
      validate_action_names! actions
      add_allowance_rule scope, actions.flatten, :forbidden
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

    def validate_action_names! actions
      if actions.include? Admission::ALL_ACTION
        raise "reserved action name #{Admission::ALL_ACTION}"
      end
    end

    def normalize_scope! scope
      case scope
        when Symbol, String then scope.to_s
        when Array then Admission.nested_scope(*scope)
        when Class then Admission.type_to_scope scope
        else raise 'invalid scope'
      end
    end

  end

  class RuleModifier

    def initialize resource: nil, **_
      if resource && !resource.is_a?(Class)
        raise "invalid resource type #{resource.to_s}"
      end
      @resource_klass = resource
    end

    def hash_arr
      [ self.class, @resource_klass ]
    end

    def hash
      hash_arr.hash
    end

    def self.create! cache, opts, value
      return true if value.nil?

      modifier = case value
        when Symbol, String then PersonMethodModifier.new(**opts).set value
        when Proc then LambdaModifier.new(**opts).set value
        when Array then MethodModifier.new(**opts).set(*value)
        else raise "invalid value for rule modifier: #{value.class}"
      end

      hash = modifier.hash
      if cache.key? hash
        cache[hash]
      else
        cache[hash] = modifier
      end
    end

    def apply_rule arbitration
      resource = arbitration.resource

      # TODO SOLVE THIS BRO
      context_type, context = arbitration.context_type_and_value
      context = arbitration.context
      args = []

      if @resource_klass
        unless resource.is_a? @resource_klass
          arbitration.process_error 'rule_invalid_resource',
              modifier: self
          return false
        end

        apply arbitration.person, [ resource, context ]

      else
        apply arbitration.person, [ context ]

      end
    end

  end

  class LambdaModifier < RuleModifier

    def set fn
      @fn = fn
      self
    end

    def hash_arr
      super + [ @fn ]
    end

    def apply person, args
      person.instance_exec *args, &@fn
    end

  end

  class PersonMethodModifier < RuleModifier

    def set method
      @method = method.to_sym
      self
    end

    def hash_arr
      super + [ @method ]
    end

    def apply person, args
      person.send @method, *args
    end

  end

  class MethodModifier < RuleModifier

    def set object, method
      @object = object
      @method = method.to_sym
      self
    end

    def hash_arr
      super + [ @object.name, @method ]
    end

    def apply _, args
      @object.send @method, person, *args
    end

  end

end
