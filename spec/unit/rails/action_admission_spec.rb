RSpec.describe Admission::Rails::ActionAdmission do

  let(:instance){ Admission::Rails::ActionAdmission.new 'aaa' }

  def mock_resolver_creation
    allow(Admission::Rails::ScopeResolver).to receive(:using).
        and_return(Admission::Rails::ScopeResolver.void)
  end

  it '.new' do
    expect(instance.controller).to eq('aaa')
    expect(instance.resolvers).to eq({})
  end

  describe '#set_resolver' do

    it 'sets single resolver' do
      instance.send :set_resolver, 'a1', :resolver
      expect(instance.resolvers).to eq({
          'a1' => :resolver
      })
    end

    it 'sets array of resolvers' do
      instance.send :set_resolver, %w[a1 b2], :resolver
      expect(instance.resolvers).to eq({
          'a1' => :resolver,
          'b2' => :resolver
      })
    end

    it 'converts actions to string' do
      instance.send :set_resolver, 1, :resolver
      instance.send :set_resolver, [:aaa, true], :resolver
      expect(instance.resolvers).to eq({
          '1' => :resolver,
          'aaa' => :resolver,
          'true' => :resolver
      })
    end

  end

  describe '#for' do

    it 'uses keyword argument as the resolver' do
      resolver = :resolver
      expect(Admission::Rails::ScopeResolver).to receive(:using).
          twice.and_return(resolver)
      instance.for :act1, resolve_to: resolver
      expect(instance.resolvers).to eq({'act1' => resolver})
      instance.for(:act1, resolve_to: resolver){}
      expect(instance.resolvers).to eq({'act1' => resolver})
    end

    it 'uses block as the resolver' do
      resolver = :resolver
      expect(Admission::Rails::ScopeResolver).to receive(:using).
          and_return(resolver)
      instance.for(:act1){}
      expect(instance.resolvers).to eq({'act1' => resolver})
    end

    it 'accepts list of actions' do
      instance.for :a1, :b2, resolve_to: ->{}
      expect(instance.resolvers.keys).to eq(%w[a1 b2])
    end

  end

  describe '#for_all' do

    it 'passes resolver as argument' do
      resolver = ->{}
      expect(instance).to receive(:for).with(
          Admission::Rails::ActionAdmission::ALL_ACTIONS,
          hash_including(resolve_to: resolver)
      )
      instance.for_all resolver
    end

    it 'passes resolver as block' do
      resolver = ->{}
      expect(instance).to receive(:for).with(
          Admission::Rails::ActionAdmission::ALL_ACTIONS,
          hash_including(resolve_to: resolver)
      )
      instance.for_all &resolver
    end

  end

  describe '#resource_for' do

    class RailsString < String
      attr_reader :singularize
      def initialize singular, plural
        super plural
        @singularize = singular
      end
    end

    let(:instance) {
      controller = double('controller')
      allow(controller).to receive(:controller_name).
          and_return(RailsString.new('user', 'users'))
      Admission::Rails::ActionAdmission.new controller
    }

    it 'uses resource finder as the resolver' do
      instance.resource_for :aaa
      resolver = instance.resolvers['aaa']
      expect(resolver.instance_variable_get '@getter').to eq(:find_user)
      expect(instance.resolvers.keys.length).to eq(1)
    end

    it 'uses scope helper as the resolver' do
      instance.resource_for :aaa, nested: true
      resolver = instance.resolvers['aaa']
      expect(resolver.instance_variable_get '@getter').to eq(:users_admission_scope)
      expect(instance.resolvers.keys.length).to eq(1)
    end

    it 'sets the finder for all actions' do
      instance.resource_for all: true
      resolver = instance.resolvers[Admission::Rails::ActionAdmission::ALL_ACTIONS]
      expect(resolver.instance_variable_get '@getter').to eq(:find_user)
      expect(instance.resolvers.keys.length).to eq(1)
    end

    it 'accepts list of actions' do
      instance.resource_for :a1, :b2
      expect(instance.resolvers.keys).to eq(%w[a1 b2])
    end

  end

  describe '#skip' do

    it 'uses void resolver' do
      instance.skip :a1
      expect(instance.resolvers).to eq('a1' => Admission::Rails::ScopeResolver.void)
    end

    it 'accepts list of actions' do
      instance.skip :a1, :b2
      expect(instance.resolvers.keys).to eq(%w[a1 b2])
    end

  end

  describe '#before_action' do

    it 'sets correct filters' do
      instance.before_action ->{}, only: :action1
      expect(instance.before_actions.last.applicable? :action1).to eq(true)

      instance.before_action ->{}, only: :action1
      expect(instance.before_actions.last.applicable? :action2).to eq(false)

      instance.before_action ->{}, only: %i[action1]
      expect(instance.before_actions.last.applicable? :action1).to eq(true)

      instance.before_action ->{}, except: :action1
      expect(instance.before_actions.last.applicable? :action1).to eq(false)

      instance.before_action ->{}, except: %i[action1]
      expect(instance.before_actions.last.applicable? :action2).to eq(true)
    end

    it 'sets correct before_action' do
      dummy = double 'controller_with_m1'
      expect(dummy).to receive(:some_method1)
      instance.before_action ->{ send :some_method1 }
      instance.before_actions.last.apply dummy

      dummy = double 'controller_with_m2'
      expect(dummy).to receive(:some_method2)
      instance.before_action &(->{ send :some_method2 })
      instance.before_actions.last.apply dummy

      dummy = double 'controller_with_m3'
      expect(dummy).to receive(:some_method3)
      instance.before_action :some_method3
      instance.before_actions.last.apply dummy
    end

  end

  describe '#scope_for_action' do

    it 'takes particular action resolver' do
      instance.resolvers['a1'] = :find_user
      expect(instance.send :scope_for_action, 'a1').to eq(:find_user)
    end

    it 'takes fallback all-action resolver' do
      instance.resolvers[Admission::Rails::ActionAdmission::ALL_ACTIONS] = :find_user
      expect(instance.send :scope_for_action, 'a1').to eq(:find_user)
    end

    it 'default resolver' do
      expect(instance.send :scope_for_action, 'a1').to eq(Admission::Rails::ScopeResolver.default)
    end

  end

  describe '#invoke!' do

    it 'requests admission with particular scope' do
      scope_resolver = double('scope_resolver')
      allow(scope_resolver).to receive(:apply).and_yield(:application)
      allow(instance).to receive(:scope_for_action).and_return scope_resolver

      controller = double 'controller'
      allow(controller).to receive(:action_name).and_return('a1')
      expect(controller).to receive(:request_admission!).with(:a1, :application)
      instance.invoke! controller
    end

    it 'applies only particular before_actions' do
      controller = double 'controller'
      allow(controller).to receive(:controller_name).and_return('app')
      allow(controller).to receive(:action_name).and_return('action')
      allow(controller).to receive(:performed?).and_return(false)

      instance.before_action :before1
      instance.before_action :before2, except: :action

      expect(controller).to receive(:before1)
      expect(controller).not_to receive(:before2)
      expect(controller).to receive(:request_admission!)
      instance.invoke! controller
    end

    it 'skip admission if performed in before filter' do
      controller = double 'controller'
      allow(controller).to receive(:controller_name).and_return('app')
      allow(controller).to receive(:action_name).and_return('action')
      allow(controller).to receive(:performed?).and_return(true)

      instance.before_action :before1

      expect(controller).to receive(:before1)
      expect(controller).not_to receive(:request_admission!)
      instance.invoke! controller
    end

  end

end