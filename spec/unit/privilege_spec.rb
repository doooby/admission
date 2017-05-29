require_relative '_helper'

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


  describe '#to_s' do

    it 'prints name and level' do
      expect(privilege.to_s).to eq('<Privilege key=man>')
    end

    it 'prints inheritance' do
      privilege_superman.inherits_from privilege
      expect(privilege_superman.to_s).to eq(
          '<Privilege key=superman inherited=[man]>'
      )
    end

  end


  describe '#dup_with_context' do

    it 'self when context is empty' do
      p2 = privilege.dup_with_context
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).to equal(privilege)

      p2 = privilege.dup_with_context nil
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).to equal(privilege)

      p2 = privilege.dup_with_context []
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).to equal(privilege)
    end

    it 'duplicates with context as array' do
      p2 = privilege.dup_with_context :moon
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).not_to equal(privilege)
      expect(p2).to eql(privilege)
      expect(p2).to have_attributes(name: :man, level: :base, context: [:moon])
    end

    it 'duplicates only change context' do
      p2 = privilege.dup_with_context [:moon]
      expect(p2).to be_a(Admission::Privilege)
      expect(p2).not_to equal(privilege)
      expect(p2).to eql(privilege)
      expect(p2).to have_attributes(name: :man, level: :base, context: [:moon])
    end

  end


  describe '.get_from_order' do

    it 'returns nil for bad name' do
      index = Admission::Privilege::OrderDefiner.define{ privilege :man }
      expect(Admission::Privilege.get_from_order index, :woman).to be_nil
    end

    it 'returns base privilege' do
      index = Admission::Privilege::OrderDefiner.define{ privilege :man }
      expect(Admission::Privilege.get_from_order index, :man).to be_eql(privilege)
    end

    it 'returns specific level privilege' do
      index = Admission::Privilege::OrderDefiner.define{ privilege :vassal, levels: %i[lord] }
      expect(Admission::Privilege.get_from_order index, :vassal, :lord).to be_eql(new_privilege :vassal, :lord)
    end

    it 'returns nil for bad level' do
      index = Admission::Privilege::OrderDefiner.define{ privilege :vassal, levels: %i[lord] }
      expect(Admission::Privilege.get_from_order index, :vassal, :pope).to be_nil
    end

  end

end