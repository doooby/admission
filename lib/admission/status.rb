module Admission
  module Status

    def privileges
      @privileges
    end

    def privileges= privileges
      @privileges = privileges.sort_by(&:name)
    end

    def admissible? action, scope_or_resource=Admission::NO_SCOPE
      return false unless privileges

      arbitration = create_admission_arbitration action, scope_or_resource
      Admission.debug_arbitration&.call arbitration, privileges

      privileges.any? do |privilege|
        arbitration.decide_on privilege
      end
    end

    def not_admissible? *args
      not admissible?(*args)
    end

    def admissible! *args
      admissible?(*args) || begin
        exception = Admission::Denied.new self, *args
        yield exception if block_given?
        raise exception
      end
    end

    # def has? sought_after
    #   false
    #   # return false unless privileges
    #   #
    #   # list = sought_after.context ? privileges.select{|p| p.context == sought_after.context} : privileges
    #   # list.any?{|p| p.eql_or_inherits? sought_after}
    # end

    # def instantiate_arbitration *args
    #   @arbiter.new person, rules, *args
    # end

    # def allowed_in_contexts *args
    #   return [] unless privileges
    #   arbitration = instantiate_arbitration *args
    #
    #   privileges.reduce [] do |list, privilege|
    #     context = privilege.context
    #
    #     unless list.include? context
    #       arbitration.prepare_sitting context
    #       list << context if arbitration.rule_per_privilege(privilege).eql? true
    #     end
    #
    #     list
    #   end
    # end

    private

    # def process_request arbitration
    #   Admission.debug_request&.call arbitration
    #
    #   privileges.any? do |privilege|
    #     arbitration.rule_on(privilege).eql? true
    #   end
    # end

  end
end