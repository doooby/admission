require_relative '../../spec_helper'

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

    it 'passes no resolver -> default' do
      expect(instance).to receive(:for).with(
          Admission::Rails::ActionAdmission::ALL_ACTIONS,
          hash_including(resolve_to: Admission::Rails::ScopeResolver.default)
      )
      instance.for_all
    end

  end

  describe '#for_resource' do

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
      instance.for_resource :aaa
      resolver = instance.resolvers['aaa']
      expect(resolver.instance_variable_get '@scope').to eq(:find_user)
      expect(instance.resolvers.keys.length).to eq(1)
    end

    it 'uses scope helper as the resolver' do
      instance.for_resource :aaa, nested: true
      resolver = instance.resolvers['aaa']
      expect(resolver.instance_variable_get '@scope').to eq(:users_admission_scope)
      expect(instance.resolvers.keys.length).to eq(1)
    end

    it 'sets the finder for all actions' do
      instance.for_resource all: true
      resolver = instance.resolvers[Admission::Rails::ActionAdmission::ALL_ACTIONS]
      expect(resolver.instance_variable_get '@scope').to eq(:find_user)
      expect(instance.resolvers.keys.length).to eq(1)
    end

    it 'accepts list of actions' do
      instance.for_resource :a1, :b2
      expect(instance.resolvers.keys).to eq(%w[a1 b2])
    end

  end

  describe '#skip' do

    it 'uses vois resolver' do
      instance.skip :a1
      expect(instance.resolvers).to eq('a1' => Admission::Rails::ScopeResolver.void)
    end

    it 'accepts list of actions' do
      instance.skip :a1, :b2
      expect(instance.resolvers.keys).to eq(%w[a1 b2])
    end

  end

  describe '#scope_for_action' do

    it 'takes particular action resolver' do
      instance.resolvers['a1'] = :find_user
      expect(instance.scope_for_action 'a1').to eq(:find_user)
    end

    it 'takes fallback all-action resolver' do
      instance.resolvers[Admission::Rails::ActionAdmission::ALL_ACTIONS] = :find_user
      expect(instance.scope_for_action 'a1').to eq(:find_user)
    end

    it 'takes scope from parent object' do
      class RootController
        def self.action_admission
          @action_admission ||= Admission::Rails::ActionAdmission.new(self)
        end
      end
      ChildController = Class.new RootController

      RootController.action_admission.resolvers['a1'] = :find_user
      expect(ChildController.action_admission.scope_for_action 'a1').to eq(:find_user)
    end

  end

end