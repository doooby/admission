class Admission::Status

  attr_reader :person, :privileges, :rules

  def initialize person, privileges, rules, arbiter
    @person = person
    @privileges = (privileges.nil? || privileges.empty?) ? nil : privileges
    @rules = rules
    @arbiter = arbiter
  end

  def can? *args
    return false unless @privileges
    process_request @arbiter.new(person, rules, *args)
  end

  def cannot? *args
    !can?(*args)
  end

  def request! *args
    can?(*args) || begin
      exception = Admission::Denied.new self, *args
      yield exception if block_given?
      raise exception
    end
  end

  def allowed_in_contexts *args
    return [] unless @privileges
    arbitration = @arbiter.new person, rules, *args

    @privileges.reduce [] do |list, privilege|
      context = privilege.context

      unless list.include? context
        arbitration.prepare_sitting *context
        list << context if arbitration.rule_per_privilege(privilege).eql? true
      end

      list
    end
  end

  private

  def process_request arbitration
    privileges.any? do |privilege|
      arbitration.prepare_sitting *privilege.context
      arbitration.rule_per_privilege(privilege).eql? true
    end
  end

end