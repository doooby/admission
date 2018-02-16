require_relative './tests'

# custom matchers
Minitest::Assertions.module_exec do

  def assert_admission status, privilege, action, scope
    arbitration = status.instantiate_arbitration action, scope
    arbitration.prepare_sitting privilege.context
    result = arbitration.rule_per_privilege(privilege).eql?(true)

    assert result, ->{ Admission::Test.assertion_failed_message arbitration, privilege }
  end

  def refute_admission status, privilege, action, scope
    arbitration = status.instantiate_arbitration action, scope
    arbitration.prepare_sitting privilege.context
    result = arbitration.rule_per_privilege(privilege).eql?(true)

    refute result, ->{ Admission::Test.refutation_failed_message arbitration, privilege }
  end

  def assert_privileges_admission status, action, scope, assert: [], refute: []
    arbitration = status.instantiate_arbitration action, scope
    assert.sort_by! &:context
    refute.sort_by! &:context

    assert.each do |privilege|
      arbitration.prepare_sitting privilege.context
      result = arbitration.rule_per_privilege(privilege).eql?(true)
      assert result, ->{ Admission::Test.assertion_failed_message arbitration, privilege }
    end

    refute.each do |privilege|
      arbitration.prepare_sitting privilege.context
      result = arbitration.rule_per_privilege(privilege).eql?(true)
      refute result, ->{ Admission::Test.refutation_failed_message arbitration, privilege }
    end

  end

end