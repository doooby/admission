class Admission::Ability

  attr_reader :status

  def initialize status
    @status = status
    @no_privileges = @status.privileges.nil? || @status.privileges.empty?
  end

  def can? action, subject
    return false if @no_privileges
    subject, object = subject_and_object subject
    process Arbitration.new(status.user, action), subject, object
  end

  def cannot? action, subject
    !can?(action, subject)
  end

  class << self

    attr_reader :rules_index

    def define_for_privileges privileges, &block


    end

    def set_up_rules &block
      @rules_index = []
      self.instance_exec &block
      remove_instance_variable :@privilege

      @rules_index = @rules_index.reduce Hash.new do |index, allowance|
        privilege = allowance[:privilege]

        actions = allowance[:actions]
        *actions = actions unless Array === actions
        actions = %i[all] if actions.include? :all

        subject_index = (index[allowance[:subject]] ||= {})
        resource_index = (index[allowance[:resource_type]] ||= {} if allowance[:resource_type])

        actions.each do |action|
          subject_arbiter = allowance[:arbiter]

          if resource_index
            action_index = (resource_index[action] ||= {})
            action_index[privilege] = allowance[:arbiter]

            subject_arbiter = true
          end

          action_index = (subject_index[action] ||= {})
          action_index[privilege] = subject_arbiter
        end

        index
      end
    end

    def privilege name, level=nil, &block
      @rules_index || raise('must be called within `set_rules` block')
      @privilege = Admission.get_privilege(name, level) || raise("no such privilege: #{name}-#{level}")
      self.instance_exec &block
      @privilege = nil
    end

    def allow subject, actions=:all
      raise 'must be called within `privilege` block' unless @privilege
      @rules_index << {
          privilege: @privilege,
          subject: subject,
          actions: actions,
          arbiter: true
      }
    end

    def disallow subject, actions=:all
      raise 'must be called within `privilege` block' unless @privilege
      @rules_index << {
          privilege: @privilege,
          subject: subject,
          actions: actions,
          arbiter: :disallow
      }
    end

    def allow_resource type, actions=:all, lambda=nil, &block
      raise 'must be called within `privilege` block' unless @privilege
      @rules_index << {
          privilege: @privilege,
          subject: resource_type_to_subject(type),
          resource_type: type,
          actions: actions,
          arbiter: lambda || block || true
      }
    end

    private

    def resource_type_to_subject type
      raise "bad resource type, must respond to `#name` (should be class)" unless type.respond_to? :name
      name = type.name.downcase
      if name.respond_to? :pluralize
        name.pluralize
      else
        raise 'Not implemented: unable to make subject id from resource without active_support'
      end

    end

  end

  private

  def subject_and_object object
    Symbol === object ? object : [objec.class, object]
  end

  def process arbitration, subject, object
    all_index = self.class.rules_index[:all]
    subject_index = self.class.rules_index[subject]
    type_index = (self.class.rules_index[object] if object)
    arbitration.introduce_indices all_index, subject_index, type_index

    status.privileges.any? do |privilege|
      arbitration.prepare_sitting object, *privilege.context
      TrueClass === arbitration.rule(privilege)
    end
  end

  class Arbitration

    attr_reader :user, :action

    def initialize user, action
      @user = user
      @action = action.to_sym
    end

    def introduce_indices all_index, subject_index, type_index
      if all_index
        @all_all_index = all_index[:all]
        @actions_all_index = all_index[action]
      end

      @all_subject_index = subject_index[:all]
      @action_subject_index = subject_index[action]

      if type_index
        @decide_for_type = true
        @all_type_index = subject_index[:all]
        @action_type_index = subject_index[action]
      end
    end

    def prepare_sitting *context
      @context = context
      @decisions = {}
    end

    def rule privilege
      decision = @decisions[privilege]
      return decision unless decision.nil?

      decision = decide_on_subject privilege
      decision = decide_on_type privilege if TrueClass === decision && @decide_for_type
      decision = decide_for_inherited privilege.inherited unless decision
      decision = false if decision.nil?

      @decisions[privilege] = decision
    end

    def decide_on_subject privilege
      decision = nil

      # special any subject index (subject = :all)
      decision = @all_all_index[privilege] if @all_all_index
      return decision if decision
      decision = @actions_all_index[privilege] if @actions_all_index
      return decision if decision

      # particular subject index
      decision = @all_subject_index[privilege] if @all_subject_index
      return decision if decision
      @action_subject_index[privilege] if @action_subject_index
    end

    def decide_on_type privilege
      decision = nil

      decision = @all_type_index[privilege] if @all_type_index
      decision = decision.call *@context if Proc === decision
      return decision if decision

      decision = @action_type_index[privilege] if @action_type_index
      decision = decision.call *@context if Proc === decision
      decision
    end

    def decide_for_inherited privileges
      return nil if privileges.nil? || privileges.empty?
      privileges.any?{|privilege| TrueClass === rule(privilege) }
    end

    def inspect
      "<Arbitration action=#{@action}>"
    end

  end

end