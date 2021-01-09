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
      arbitration.process self
      arbitration.result
    end

    def not_admissible? *args
      not admissible?(*args)
    end

    def admissible! action, scope_or_resource=Admission::NO_SCOPE
      return false unless privileges
      arbitration = create_admission_arbitration action, scope_or_resource
      arbitration.process self
      unless arbitration.result
        exception = Admission::Denied.new arbitration
        yield exception if block_given?
        raise exception
      end
    end

  end
end
