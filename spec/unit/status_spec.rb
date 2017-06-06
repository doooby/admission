require_relative './_helper'

RSpec.describe Admission::Status do

  def privilege context
    @fake_privilege_klass ||= Struct.new(:context, :inherited)
    @fake_privilege_klass.new context
  end

  describe '#new' do

    it 'sets privileges to nil' do
      instance = Admission::Status.new :person, nil, :rules, :arbiter
      expect(instance).to have_inst_vars(
          person: :person,
          privileges: nil,
          rules: :rules,
          arbiter: :arbiter
      )

      instance = Admission::Status.new :person, [], :rules, :arbiter
      expect(instance).to have_inst_vars(
          person: :person,
          privileges: nil,
          rules: :rules,
          arbiter: :arbiter
      )
    end

    it 'sets privileges' do
      instance = Admission::Status.new :person, ['kkk'], :rules, :arbiter
      expect(instance).to have_inst_vars(
          person: :person,
          privileges: ['kkk'],
          rules: :rules,
          arbiter: :arbiter
      )
    end

  end

  describe '#allowed_in_contexts' do

    it 'returns empty list for blank privileges' do
      instance = Admission::Status.new :person, nil, :rules, :arbiter
      expect(instance.allowed_in_contexts).to eq([])
    end

    it 'lists only context for which any privilege allows it' do
      priv1 = privilege text: '1'
      priv2 = privilege text: '2'
      rules = {can: {priv1 => true}}
      instance = Admission::Status.new nil, [priv1, priv2], rules, Admission::Arbitration

      list = instance.allowed_in_contexts :can
      expect(list).to eq([priv1.context])
    end

  end

end