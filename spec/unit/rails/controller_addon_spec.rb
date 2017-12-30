require_relative '../../spec_helper'

RSpec.describe Admission::Rails::ControllerAddon do

  ADDON = Admission::Rails::ControllerAddon

  def stub_action_admission
    action_admission = double('ActionAdmission')
    stub_const('Admission::Rails::ActionAdmission', action_admission)

    instance = double('ActionAdmission.new')
    allow(instance).to receive(:for_all)
    allow(action_admission).to receive(:new).and_return(instance)

    [action_admission, instance]
  end

  let(:controller){
    controller = Class.new do
      def action_name; 'home'; end
    end
    controller.include ADDON
  }

  it 'sets default configuration on inclusion' do
    stub_action_admission
    controller
    expect(controller.action_admission).to have_received(:for_all).with(no_args)
  end

  it 'caches action_admission instance' do
    klass, _ = stub_action_admission
    controller.action_admission
    controller.action_admission
    child_controller = Class.new controller
    child_controller.action_admission
    child_controller.action_admission
    expect(klass).to have_received(:new).with(controller)
    expect(klass).to have_received(:new).with(child_controller)
  end

  it 'adds instance methods' do
    stub_action_admission
    expect(controller.private_method_defined? :request_admission!).to be_truthy
    expect(controller.private_method_defined? :assure_admission).to be_truthy
  end

  it '#assure_admission raises no scope error' do
    _, instance = stub_action_admission
    allow(instance).to receive(:scope_for_action)
    expect{
      controller.new.send :assure_admission
    }.to raise_error(Admission::Rails::ScopeNotDefined)
  end

  it '#assure_admission request admission with particular scope' do
    _, instance = stub_action_admission
    scope_resolver = double('scope_resolver')
    allow(scope_resolver).to receive(:apply).and_yield(:application)
    allow(instance).to receive(:scope_for_action).and_return(scope_resolver)

    controller_instance = controller.new
    expect(controller_instance).to receive(:request_admission!).with(:home, :application)
    controller_instance.send :assure_admission
  end

end