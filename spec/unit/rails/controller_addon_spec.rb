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
      def self.before_action *_; end
    end
    controller.include ADDON
  }

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

end