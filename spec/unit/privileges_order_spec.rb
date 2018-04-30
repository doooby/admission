require_relative '../spec_helper'

RSpec.describe Admission::PrivilegesOrder do

  let :order do
    Admission.define_privileges do
      privilege :man
      privilege :vassal, levels: %i[lord], inherits: %i[man]
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

end
