require_relative './tests'

Minitest::Assertions.module_exec do

  def assert_admission_rule status, request, scope, privileges
    Admission::Tests.process_rule status, privileges, request, scope do |result, privilege, arbitration|
      assert result, ->{ Admission::Tests.fail_message arbitration.case_to_s, [privilege], nil }
    end
  end

  def refute_admission_rule status, request, scope, privileges
    Admission::Tests.process_rule status, privileges, request, scope do |result, privilege, arbitration|
      refute result, ->{ Admission::Tests.fail_message arbitration.case_to_s, nil, [privilege] }
    end
  end

  def admission_rule request
    helper = Admission::Tests::RuleHelper.new self, request
    yield helper
  end

end

Admission::Tests::RuleHelper.class_exec do
  def assert
    @context.assertions += 1

    unless result
      raise Minitest::Assertion, fail_msg
    end
  end
end

if defined?(Admission::Tests::ActionHelper)

  Minitest::Assertions.module_exec do
    def admission_action_mock controller, &block
      Admission::Tests::ActionHelper.mock(
        controller,
        self, 
        &block
      )
    end
  end

  Admission::Tests::ActionHelper.class_exec do 
    def assert scope
      @context.assertions += 1
      @context.assert_equal scope, result
    end
  end

end