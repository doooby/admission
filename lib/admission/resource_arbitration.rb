class Admission::ResourceArbitration < Admission::Arbitration

  RESOURCE_BLOCK_MARK = '@resource_arbiter'.freeze

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
        decision = process_proc_decision decision

      elsif @resource && Symbol === decision && decision != :forbidden
        decision = process_method_decision decision

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
    resource = if @resource
      Admission::ResourceArbitration.resource_to_s @resource
    end
    "#{request} -> #{@scope}#{' ' if resource}#{resource if resource}"
  end

  def self.type_to_scope type
    :"#{type.name.downcase}s"
  end

  def self.nested_scope resource, scope
    resource = type_to_scope resource unless resource.is_a? Symbol
    "#{resource}:#{scope}".to_sym
  end

  def self.resource_to_s resource
    if resource.respond_to? :id
      "#{resource.class.name}[#{resource.id || 'new'}]"
    else
      resource.to_s
    end
  end

  private

  def process_proc_decision proc
    if proc.instance_variable_get RESOURCE_BLOCK_MARK
      @person.instance_exec @resource, @context, &proc
    else
      @person.instance_exec @context, &proc
    end
  end

  def process_method_decision method
    if @resource.respond_to? method
      @resource.send method, @person, @context
    else
      false
    end
  end

  class RulesBuilder < Admission::Arbitration::RulesBuilder

    def allow scope, *actions, &block
      validate_action_names! actions
      mark_resource_arbiter! block, false if block
      add_allowance_rule actions.flatten, (block || true),
          scope: normalize_scope(scope)
    end

    def allow_all scope, &block
      mark_resource_arbiter! block, false if block
      add_allowance_rule [Admission::ALL_ACTION], (block || true),
          scope: normalize_scope(scope)
    end

    def forbid scope, *actions
      validate_action_names! actions
      add_allowance_rule actions.flatten, :forbidden,
          scope: normalize_scope(scope)
    end

    def allow_resource resource, *actions, rule:nil, &block
      validate_action_names! actions
      if block
        mark_resource_arbiter! block, true
        rule = block

      elsif Symbol === rule
        raise 'rule cannot be `:forbidden`' if rule === :forbidden

      else
        raise 'pass either symbol as a rule or block'

      end

      add_allowance_rule actions.flatten, rule,
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

    def mark_resource_arbiter! block, as_resource
      is_resource = block.instance_variable_get RESOURCE_BLOCK_MARK

      if as_resource
        if is_resource.eql? false
          raise 'Bad reuse of block rule: already non-resource arbiter'
        end

      else
        if is_resource.eql? true
          raise 'Bad reuse of block rule: already resource arbiter'
        end

      end

      block.instance_variable_set RESOURCE_BLOCK_MARK, as_resource
    end

  end

end