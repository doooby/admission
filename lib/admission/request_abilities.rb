class Admission::Ability::Requests

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

class Admission::Ability

  def self.define_request_abilities privilege_order, &block
    builder = Admission::Ability::Requests.new privilege_order
    builder.instance_exec &block
    builder.create_index
  end

end