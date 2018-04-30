require_relative '../spec_helper'

RSpec.describe Admission::Privilege do

  def new_privilege *args
    Admission::Privilege.new *args
  end

  let(:privilege){ new_privilege :man }

  let(:privilege_superman){ new_privilege :superman }
  let(:privilege_uberman){ new_privilege :uberman }


  describe '#new' do

    it 'create base privilege' do
      expect(new_privilege :man).to have_attributes(name: :man, level: :base)
    end

    it 'creates with level' do
      expect(new_privilege :man, :lvl1).to have_attributes(name: :man, level: :lvl1)
    end

    it 'changes names to symbols' do
      expect(new_privilege 'man', 'lvl1').to have_attributes(name: :man, level: :lvl1)
    end

    it 'hash is combination of name and level' do
      expect(privilege.hash).to eq([:man, :base].hash)
    end

  end


  describe '#inherited' do

    it 'nothing' do
      expect(privilege.inherited).to be_nil
    end

    it 'single item' do
      privilege.inherits_from privilege_superman
      expect(privilege.inherited).to contain_exactly(privilege_superman)
    end

    it 'arguments list' do
      privilege.inherits_from privilege_superman, privilege_uberman
      expect(privilege.inherited).to contain_exactly(privilege_superman, privilege_uberman)
    end

  end


  describe '#eql?' do

    it 'compares by hash' do
      p1 = new_privilege :man
      p2 = new_privilege :man
      expect(p1).to eql(p2)

      p2.instance_variable_set :@hash, nil.hash
      expect(p1).not_to eql(p2)

      expect(p1).not_to eql(new_privilege :self)
    end

  end


  describe '#eql_or_inherits?' do

    it 'returns true since it equals sought privilege' do
      expect(privilege.eql_or_inherits? privilege).to eq(true)
    end

    it 'return false when does not inherit any' do
      expect(privilege_superman.eql_or_inherits? privilege_uberman).to eq(false)
    end

    it 'finds nested inherited privilege and therefore evaluates to true' do
      top_privilege = new_privilege 'man', 'top'
      top_privilege.inherits_from new_privilege('man', 'branch'),
          new_privilege('man', 'middle').tap{|p| p.inherits_from new_privilege('man')}

      sought = new_privilege 'man'
      expect(top_privilege.eql_or_inherits? sought).to eq(true)
      expect(top_privilege.eql_or_inherits? new_privilege('man', 'nope')).to eq(false)
    end

    it 'ignores context' do
      expect(privilege.eql_or_inherits? privilege.dup_with_context(:czech)).to eq(true)
    end

  end


  describe '#inspect' do

    it 'prints name and level' do
      expect(privilege).to receive(:text_key).and_call_original
      expect(privilege.inspect).to eq('#<Privilege key=man>')
    end

    it 'prints inheritance' do
      privilege_superman.inherits_from privilege
      expect(privilege).to receive(:text_key).and_call_original
      expect(privilege_superman.inspect).to eq(
          '#<Privilege key=superman inherited=[man]>'
      )
    end

  end

  describe '#to_s' do

    it 'prints name and level' do
      expect(privilege).to receive(:text_key).and_call_original
      expect(privilege.to_s).to eq('privilege man')
    end

    it 'prints inheritance' do
      privilege2 = new_privilege('mans', 'not').dup_with_context 'hot'
      expect(privilege2).to receive(:text_key).and_call_original
      expect(privilege2.to_s).to eq('privilege mans-not, context hot')
    end

  end


  describe '#dup_with_context' do

    it 'self when context is nil' do
      p2 = privilege.dup_with_context
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).to equal(privilege)

      p2 = privilege.dup_with_context nil
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).to equal(privilege)
    end

    it 'duplicates only change context' do
      p2 = privilege.dup_with_context :moon
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).not_to equal(privilege)
      expect(p2).to eql(privilege)
      expect(p2).to have_attributes(name: :man, level: :base, context: :moon)
    end

  end

end