class Admission::Status

  attr_reader :person, :privileges, :rules

  def initialize person, privileges, rules, arbiter
    @person = person
    @privileges = (privileges && !privileges.empty?) ? privileges : nil
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

  private

  def process_request arbitration
    privileges.any? do |privilege|
      arbitration.prepare_sitting *privilege.context
      arbitration.rule_per_privilege(privilege).eql? true
    end
  end

end