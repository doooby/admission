class Admission::ResourceArbitration < Admission::Arbitration

  attr_reader :scope, :resource

  def initialize person, rules_index, request, scope_or_resource
    @person = person
    @scope, @resource = scope_and_resource scope_or_resource
    @rules_index = rules_index[@scope] || {}
    @request = request.to_sym
    @decisions = {}
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
        resource, nested_scope = scope_or_resource
        [self.class.nested_scope(resource.class, nested_scope), resource]
      else
        [self.class.type_to_scope(scope_or_resource.class), scope_or_resource]
    end
  end

  def case_to_s
    "`#{@request}` over `#{@scope}`#{Admission::ResourceArbitration.resource_to_s @resource if @resource}"
  end

  def self.type_to_scope type
    :"#{type.name.downcase}s"
  end

  def self.nested_scope resource, scope
    resource = type_to_scope resource unless resource.is_a? Symbol
    "#{resource}:#{scope}".to_sym
  end

  def self.resource_to_s resource
    ", resource: #{resource.respond_to?(:id) ? "#{resource.class.name}[#{resource.id}]" : resource}"
  end

  class RulesBuilder < Admission::Arbitration::RulesBuilder

    def allow scope, *actions, &block
      validate_action_names! actions
      add_allowance_rule actions.flatten, (block || true),
          scope: normalize_scope(scope)
    end

    def allow_all scope, &block
      add_allowance_rule [Admission::ALL_ACTION], (block || true),
          scope: normalize_scope(scope)
    end

    def forbid scope, *actions
      validate_action_names! actions
      add_allowance_rule actions.flatten, :forbidden,
          scope: normalize_scope(scope)
    end

    def allow_resource resource, *actions, &block
      validate_action_names! actions
      raise "block not given" unless block
      block.instance_variable_set :@resource_arbiter, true
      add_allowance_rule actions.flatten, block,
          scope: normalize_scope(resource)
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

      index_instance.values.each do |h|
        h.values.each &:freeze
        h.freeze
      end
      index_instance.freeze
    end

    private

    def normalize_scope scope
      case scope
        when Symbol then scope
        when Array then Admission::ResourceArbitration.nested_scope(*scope)
        when Class then Admission::ResourceArbitration.type_to_scope(scope)
        else raise 'invalid scope'
      end
    end

  end

end