class Admission::Status

  attr_reader :person, :privileges, :rules
  attr_accessor :debug

  def initialize person, privileges, rules, arbiter
    @person = person
    @rules = rules
    @arbiter = arbiter

    @privileges = if privileges.nil? || privileges.empty?
      nil

    else
      # sort privileges
      # convenient as for arbitration doesn't have to switch between contexts too often
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
    process_request instantiate_arbitration(*args)
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

    list = sought.context ? privileges.select{|p| p.context == sought.context} : privileges
    list.any?{|p| p.eql_or_inherits? sought}
  end

  def instantiate_arbitration *args
    @arbiter.new person, rules, *args
  end

  def allowed_in_contexts *args
    return [] unless privileges
    arbitration = instantiate_arbitration *args

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
    Admission.debug_request&.call arbitration

    privileges.any? do |privilege|
      arbitration.rule_on(privilege).eql? true
    end
  end

end