require_relative './tests'

Minitest::Assertions.module_exec do

  def get_privilege name, context=nil
    p = Admission::Tests.order.get *Admission::Privilege.split_text_key(name)
    p = p.dup_with_context context if context
    p
  end

  def assert_admission status, privilege, request, scope
    arbitration = status.instantiate_arbitration request, scope
    arbitration.prepare_sitting privilege.context
    result = arbitration.rule_per_privilege(privilege).eql?(true)

    assert result, ->{ Admission::Tests.assertion_failed_message arbitration, privilege }
  end

  def refute_admission status, privilege, request, scope
    arbitration = status.instantiate_arbitration request, scope
    arbitration.prepare_sitting privilege.context
    result = arbitration.rule_per_privilege(privilege).eql?(true)

    refute result, ->{ Admission::Tests.refutation_failed_message arbitration, privilege }
  end

  def separate_privileges *args, &block
    Admission::Tests.separate_privileges *args, &block
  end

  def assert_admissions_evaluation evaluation, request, to_assert, to_refute
    should, should_not = evaluation.for_request(request).evaluate_groups to_assert, to_refute
    assert should.empty?, ->{
      Admission::Tests.assertion_failed_message evaluation.arbitration,
          "any of: #{should.map{|p| p.privilege.to_s}.join ', '}"
    }
    assert should_not.empty?, ->{
      Admission::Tests.refutation_failed_message evaluation.arbitration,
          "any of: #{should_not.map{|p| p.privilege.to_s}.join ', '}"
    }
  end

end

if defined?(Mocha::Expectation) && defined?(Admission::Rails)

  Admission::Tests.module_exec do

    def self.create_action_mock controller
      ->(action, scope, params: nil, &block){
        c = controller.new
        c.stubs(:action_name).returns action
        c.expects(:request_admission!).
            with(action.to_sym, scope)
        c.stubs(:params).returns params if params
        block.call c if block
        c.send :assure_admission
      }
    end

  end

end
