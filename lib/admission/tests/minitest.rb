require_relative './tests'

Minitest::Assertions.module_exec do

  def get_privilege name, context=nil
    p = Admission::Tests.order.get *Admission::Privilege.split_text_key(name)
    p = p.dup_with_context context if context
    p
  end

  def assert_admission status, privilege, action, scope
    arbitration = status.instantiate_arbitration action, scope
    arbitration.prepare_sitting privilege.context
    result = arbitration.rule_per_privilege(privilege).eql?(true)

    assert result, ->{ Admission::Tests.assertion_failed_message arbitration, privilege }
  end

  def refute_admission status, privilege, action, scope
    arbitration = status.instantiate_arbitration action, scope
    arbitration.prepare_sitting privilege.context
    result = arbitration.rule_per_privilege(privilege).eql?(true)

    refute result, ->{ Admission::Tests.refutation_failed_message arbitration, privilege }
  end

  def separate_privileges *args, &block
    Admission::Tests.separate_privileges *args, &block
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
