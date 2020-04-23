RSpec.describe Admission::PrivilegesOrder do

  let :order do
    Admission.define_privileges do
      privilege :man
      privilege :vassal, levels: %i[lord], inherits: %i[man]

      privilege :god
    end
  end

  describe '#get' do

    it 'returns nil for bad name' do
      expect(order.get :woman).to be_nil
    end

    it 'returns base privilege' do
      expect(order.get :man).to be_eql(Admission::Privilege.new :man)
    end

    it 'returns specific level privilege' do
      expect(order.get :vassal, :lord).to be_eql(Admission::Privilege.new :vassal, :lord)
    end

    it 'returns nil for bad level' do
      expect(order.get :vassal, :pope).to be_nil
    end

  end

  describe '#list' do

    it 'caches the list' do
      l1 = order.to_list
      l2 = order.to_list
      expect(l1).to equal(l2)
    end

    it 'doesn\'t hold duplicities' do
      expect(order.to_list.map(&:text_key).sort).to eq(%w[god man vassal vassal-lord])
    end

  end

  describe '#entitled_for' do

    it 'lists all entitled' do
      man = Admission::Privilege.new :man
      expect(order.entitled_for(man).map(&:text_key).sort).to eq(%w[man vassal vassal-lord])
    end

  end

end
