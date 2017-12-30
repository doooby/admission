require_relative '../../spec_helper'

RSpec.describe Admission::Rails::ScopeResolver do

  it '.new freezes the instance' do
    instance = Admission::Rails::ScopeResolver.new nil
    expect(instance.instance_variable_get '@scope').to be_nil
    expect(instance).to be_frozen
  end

  describe '#apply' do

    it 'Symbol scope' do
      instance = Admission::Rails::ScopeResolver.new :to_s
      applied = false

      instance.apply 42 do |value|
        expect(value).to eq('42')
        applied = true
      end

      expect(applied).to be_truthy
    end

    it 'Proc scope' do
      instance = Admission::Rails::ScopeResolver.new ->{ to_s }
      applied = false

      instance.apply 42 do |value|
        expect(value).to eq('42')
        applied = true
      end

      expect(applied).to be_truthy
    end

    it 'nil scope' do
      instance = Admission::Rails::ScopeResolver.new nil

      instance.apply 42 do
        fail 'should not be called'
      end
    end

  end

  describe '.using' do

    it 'returns the very same instance' do
      instance = Admission::Rails::ScopeResolver.using Admission::Rails::ScopeResolver.void
      expect(instance).to be(Admission::Rails::ScopeResolver.void)
    end

    it 'creates instance' do
      instance = Admission::Rails::ScopeResolver.using :to_s
      expect(instance.instance_variable_get '@scope').to be(:to_s)

      proc = ->{}
      instance = Admission::Rails::ScopeResolver.using proc
      expect(instance.instance_variable_get '@scope').to be(proc)
    end

    it 'prints nice error message' do
      expect{ Admission::Rails::ScopeResolver.using nil }.to raise_error(
          'Function to resolve the admission scope needed.'+
              ' Pass a block or `resolve_to:` parameter.'
      )
    end

  end

end