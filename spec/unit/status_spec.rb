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

    it 'sets privileges and freezes them' do
      instance = Admission::Status.new :person, [:czech], :rules, :arbiter
      expect(instance).to have_inst_vars(
          person: :person,
          privileges: [:czech],
          rules: :rules,
          arbiter: :arbiter
      )
      expect(instance.privileges).to be_frozen
    end

    it 'sorts privileges by context' do
      instance = Admission::Status.new :person, [
          privilege(nil),
          privilege(:czech),
          privilege(15),
          privilege(:czech),
          privilege({a: 15}),
          privilege({a: {f: 1}}),
          privilege(nil),
          privilege({a: 15}),
      ], :rules, :arbiter
      expect(instance.privileges.map(&:context)).to eq([
          nil, nil, :czech, :czech, 15, {:a=>15}, {:a=>15}, {:a=>{:f=>1}}
      ])
      expect(instance.privileges).to be_frozen
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