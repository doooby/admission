class Admission::Arbitration
  VALID_DECISION = [true, false, :forbidden, nil]

  def initialize status, request
    @person = status.person
    @rules_index = status.rules
    @request = request.to_sym
  end

  def prepare_sitting *context
    @context = context
    @decisions = {}
  end

  def rule_per_privilege privilege
    decision = @decisions[privilege]
    return decision unless decision.nil?

    decision = decide privilege

    decision = false if decision.nil?
    @decisions[privilege] = decision
  end

  def make_decision from_rules, privilege
    if from_rules
      decision = from_rules[privilege]
      decision = @person.instance_exec *@context, &decision if Proc === decision

      raise 'bad decision' unless VALID_DECISION.include? decision
      decision
    end
  end

  def decide_per_inheritance privilege
    inherited = privilege.inherited
    return nil if inherited.nil? || inherited.empty?

    inherited.any? do |p|
      rule = rule_per_privilege p
      return rule if rule.eql? :forbidden
      rule.eql? true
    end
  end

  def decide privilege
    decision = make_decision @rules_index[@request], privilege
    return decision if decision.eql?(:forbidden) || decision.eql?(true)

    decision2 = decide_per_inheritance privilege
    return false if decision2.eql?(:forbidden) && decision.eql?(false)
    return decision2 if decision2.eql?(:forbidden) || decision2.eql?(true)

    make_decision @rules_index[:all], privilege
  end

  def self.define_rules privilege_order, &block
    builder = Admission::Arbitration::RulesBuilder.new privilege_order
    builder.instance_exec &block
    builder.create_index
  end

  class RulesBuilder

    attr_reader :privilege_order

    def initialize privilege_order
      @rules = []
      @privilege_order = privilege_order
    end

    def privilege name, level=nil
      @privilege = Admission::Privilege.get_from_order privilege_order, name, level
      raise "no such privilege: #{name}-#{level}" unless @privilege
      yield
      @privilege = nil
    end

    def allow *actions, &block
      add_allowance_rule actions.flatten, (block || true)
    end

    def allow_all &block
      add_allowance_rule %i[all], (block || true)
    end

    def forbid *actions
      add_allowance_rule actions.flatten, :forbidden
    end

    def add_allowance_rule actions, arbiter, **options
      raise 'must be called within `privilege` block' unless @privilege

      @rules << options.merge!(
          privilege: @privilege,
          actions: actions,
          arbiter: arbiter
      )
    end

    def create_index
      index_instance = @rules.reduce Hash.new do |index, allowance|
        privilege = allowance[:privilege]
        actions = allowance[:actions]
        arbiter = allowance[:arbiter]

        actions.each do |action|
          action_index = (index[action] ||= {})
          action_index[privilege] = arbiter
        end

        index
      end

      index_instance.freeze
    end

  end

end