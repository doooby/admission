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
          decision = @person.instance_exec @resource, *@context, &decision
        else
          decision = @person.instance_exec *@context, &decision
        end
      end

      unless Admission::VALID_DECISION.include? decision
        raise "invalid decision: #{decision}"
      end

      decision
    end
  end

  def scope_and_resource scope_or_resource
    if scope_or_resource.is_a? Symbol
      [scope_or_resource]
    else
      [Admission.type_to_scope(scope_or_resource.class).to_sym, scope_or_resource]
    end
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

    def allow_resource scope, *actions, &block
      raise "reserved action name #{Admission::ALL_ACTION}" if actions.include? Admission::ALL_ACTION
      block.instance_variable_set :@resource_arbiter, true if block
      scope = Admission.type_to_scope(scope).to_sym unless scope.is_a? Symbol
      add_allowance_rule actions.flatten, (block || true), scope: scope
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