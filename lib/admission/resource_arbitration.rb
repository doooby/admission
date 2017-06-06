class Admission::ResourceArbitration < Admission::Arbitration

  def initialize person, rules_index, request, scope_or_resource
    @person = person
    scope, @resource = scope_and_resource scope_or_resource
    @rules_index = rules_index[scope] || {}
    @request = request.to_sym
  end

  def make_decision from_rules, privilege
    if from_rules
      decision = from_rules[privilege]
      if Proc === decision
        if decision.instance_variable_get :@resource_arbiter
          decision = @person.instance_exec @resource, @context, &decision
        else
          decision = @person.instance_exec @context, &decision
        end
      end

      unless Admission::VALID_DECISION.include? decision
        raise "invalid decision: #{decision}"
      end

      decision
    end
  end

  def scope_and_resource scope_or_resource
    case scope_or_resource
      when Symbol
        [scope_or_resource]
      when Array
        resource, scope = scope_or_resource
        [self.class.nested_scope(resource.class, scope), resource]
      else
        [self.class.type_to_scope(scope_or_resource.class).to_sym, scope_or_resource]
    end
  end

  def self.type_to_scope_resolution proc=nil, &block
    @type_to_scope = proc || block
  end

  def self.type_to_scope type
    scope = @type_to_scope && @type_to_scope.call(type)
    scope ? scope.to_sym : :"#{type.name.downcase}s"
  end

  def self.nested_scope resource, scope
    resource = type_to_scope resource unless resource.is_a? Symbol
    "#{resource}:#{scope}".to_sym
  end

  class RulesBuilder < Admission::Arbitration::RulesBuilder

    def allow scope, *actions, &block
      raise "reserved action name #{Admission::ALL_ACTION}" if actions.include? Admission::ALL_ACTION
      raise "invalid scope name" unless scope.respond_to? :to_sym
      add_allowance_rule actions.flatten, (block || true), scope: scope.to_sym
    end

    def allow_all scope, &block
      raise "invalid scope name" unless scope.respond_to? :to_sym
      add_allowance_rule [Admission::ALL_ACTION], (block || true), scope: scope.to_sym
    end

    def forbid scope, *actions
      raise "reserved action name #{Admission::ALL_ACTION}" if actions.include? Admission::ALL_ACTION
      raise "invalid scope name" unless scope.respond_to? :to_sym
      add_allowance_rule actions.flatten, :forbidden, scope: scope.to_sym
    end

    def allow_resource resource, *actions, &block
      raise "reserved action name #{Admission::ALL_ACTION}" if actions.include? Admission::ALL_ACTION
      raise "block not given" unless block
      block.instance_variable_set :@resource_arbiter, true
      scope = case resource
        when Symbol then resource
        when Array then nested_scope(*resource)
        else type_to_scope(resource)
      end
      add_allowance_rule actions.flatten, block, scope: scope
    end

    def type_to_scope resource
      Admission::ResourceArbitration.type_to_scope resource
    end

    def nested_scope resource, scope
      Admission::ResourceArbitration.nested_scope resource, scope
    end

    def create_index
      index_instance = @rules.reduce Hash.new do |index, allowance|
        privilege = allowance[:privilege]
        actions = allowance[:actions]
        scope = allowance[:scope]
        arbiter = allowance[:arbiter]

        scope_index = (index[scope] ||= {})

        actions.each do |action|
          action_index = (scope_index[action] ||= {})
          action_index[privilege] = arbiter
        end

        index
      end

      index_instance.freeze
    end

  end

end