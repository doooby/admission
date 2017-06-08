class Admission::Status

  attr_reader :person, :privileges, :rules

  def initialize person, privileges, rules, arbiter
    @person = person
    @rules = rules
    @arbiter = arbiter

    @privileges = if privileges.nil? || privileges.empty?
      nil

    else
      grouped = privileges.inject Hash.new do |h, p|
        hash = p.context.hash rescue nil.hash
        (h[hash] ||= []) << p
        h
      end

      grouped.values.flatten.freeze
    end
  end

  def can? *args
    return false unless privileges
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

  def has? sought
    return false unless privileges

    list = privilege.context ? privileges.select{|p| p.context == privilege.context} : privileges
    list.any?{|p| p.eql_or_inherits? sought}
  end

  def allowed_in_contexts *args
    return [] unless privileges
    arbitration = @arbiter.new person, rules, *args

    privileges.reduce [] do |list, privilege|
      context = privilege.context

      unless list.include? context
        arbitration.prepare_sitting context
        list << context if arbitration.rule_per_privilege(privilege).eql? true
      end

      list
    end
  end

  private

  def process_request arbitration
    privileges.any? do |privilege|
      arbitration.prepare_sitting privilege.context
      arbitration.rule_per_privilege(privilege).eql? true
    end
  end

end