require_relative '../_helper'

RSpec.describe Admission::Privilege::OrderDefiner do

  def define_privileges &block
    Admission::Privilege::OrderDefiner.define &block
  end

  def privilege *args, inherits: nil
    p = Admission::Privilege.new *args
    p.inherits_from inherits if inherits
    p
  end

  let(:definer){ Admission::Privilege::OrderDefiner.new }


  describe '.define' do

    it 'builds empty index' do
      index = define_privileges{}
      expect(index).to be_a(Hash)
      expect(index).to be_empty
      expect(index).to be_frozen
    end

    it 'builds single privilege' do
      index = define_privileges{ privilege :man, levels: %i[commoner count] }
      expect(index.keys).to eq(%i[man])
      expect(index[:man].keys).to eq(%i[^ base commoner count])
      expect(index[:man][:base].inherited).to be_nil
    end

    it 'builds with inheritance' do
      index = define_privileges do
        privilege :man
        privilege :vassal, levels: %i[lord], inherits: :man
      end

      # structure
      expect(index.keys).to eq(%i[man vassal])
      expect(index[:man].keys).to eq(%i[^ base])
      expect(index[:vassal].keys).to eq(%i[^ base lord])

      # inheritance
      expect(index[:man][:base].inherited).to be_nil
      expect(index[:vassal][:base].inherited).to eql([privilege(:man)])
      expect(index[:vassal][:lord].inherited).to eql([privilege(:vassal)])
    end

  end


  describe '#privilege' do

    it 'adds privilege with no levels' do
      definer.privilege :man
      expect(definer.definitions.size).to eq(1)
      expect(definer.definitions[:man][:inherits]).to be_nil
      expect(definer.definitions[:man][:levels]).to eql([privilege(:man)])
    end

    it 'adds privilege with no levels by string' do
      definer.privilege 'man'
      expect(definer.definitions.size).to eq(1)
      expect(definer.definitions[:man][:inherits]).to be_nil
      expect(definer.definitions[:man][:levels]).to eql([privilege(:man)])
    end

    it 'adds privilege array of levels' do
      definer.privilege :man, levels: %i[commoner count]
      expect(definer.definitions.size).to eq(1)
      expect(definer.definitions[:man][:inherits]).to be_nil
      expect(definer.definitions[:man][:levels]).to eql([
          privilege(:man), privilege(:man, :commoner), privilege(:man, :count)
      ])
    end

    it 'adds privilege that inherits single other' do
      definer.privilege :vassal, inherits: :man
      expect(definer.definitions.size).to eq(1)
      expect(definer.definitions[:vassal][:inherits]).to eq([:man])
    end

    it 'adds privilege that inherits multiple others' do
      definer.privilege :vassal, inherits: %i[man woman apache-helicopter]
      expect(definer.definitions.size).to eq(1)
      expect(definer.definitions[:vassal][:inherits]).to eq([:man, :woman, :'apache-helicopter'])
    end

    it 'adds multiple privileges' do
      definer.privilege :man
      definer.privilege :vassal
      expect(definer.definitions.keys).to eq(%i[man vassal])
    end

  end


  describe '#setup_inheritance' do

    it 'sets inheritance' do
      definer.privilege :man
      definer.privilege :vassal, inherits: :man
      definer.send :setup_inheritance

      vassal = definer.definitions[:vassal]
      expect(vassal[:levels]).to eql([privilege(:vassal)])
      expect(vassal[:levels].first.inherited).to eql([privilege(:man)])
    end

    it 'sets inheritance to top level' do
      definer.privilege :man, levels: %i[commoner count]
      definer.privilege :vassal, inherits: :man
      definer.send :setup_inheritance

      vassal = definer.definitions[:vassal]
      expect(vassal[:levels]).to eql([privilege(:vassal)])
      expect(vassal[:levels].first.inherited).to eql([privilege(:man, :count)])
    end

    it 'sets inheritance throughout levels' do
      definer.privilege :man
      definer.privilege :vassal, inherits: :man, levels: %i[lord]
      definer.send :setup_inheritance

      vassal = definer.definitions[:vassal]
      expect(vassal[:levels]).to eql([privilege(:vassal), privilege(:vassal, :lord)])
      expect(vassal[:levels][0].inherited).to eql([privilege(:man)])
      expect(vassal[:levels][1].inherited).to eql([privilege(:vassal)])
    end

  end


  describe '#build_index' do

    it 'returns hash with single privileges' do
      definer.privilege :man
      index = definer.send :build_index
      expect(index).to be_a(Hash)
      expect(index.keys).to eq([:man])

      man = index.values.first
      expect(man.keys).to eq(%i[^ base])
      expect(man.values).to eql([privilege(:man), privilege(:man)])
    end

    it 'builds index for privilege with levels' do
      definer.privilege :man, levels: %i[commoner count]
      index = definer.send :build_index
      expect(index).to be_a(Hash)
      expect(index.keys).to eq([:man])

      man = index[:man]
      expect(man.keys).to eq(%i[^ base commoner count])
      expect(man[:'^']).to eql(privilege :man, :count)
      expect(man[:base]).to eql(privilege :man)
      expect(man[:commoner]).to eql(privilege :man, :commoner)
      expect(man[:count]).to eql(privilege :man, :count)
    end

    it 'returns hash with more privileges' do
      definer.privilege :man
      definer.privilege :vassal, levels: %i[lord]
      index = definer.send :build_index
      expect(index).to be_a(Hash)
      expect(index.keys).to eq([:man, :vassal])

      man = index[:man]
      expect(man.keys).to eq(%i[^ base])
      expect(man[:'^']).to eql(privilege :man)
      expect(man[:base]).to eql(privilege :man)

      vassal = index[:vassal]
      expect(vassal.keys).to eq(%i[^ base lord])
      expect(vassal[:'^']).to eql(privilege :vassal, :lord)
      expect(vassal[:base]).to eql(privilege :vassal)
      expect(vassal[:lord]).to eql(privilege :vassal, :lord)
    end

  end

end