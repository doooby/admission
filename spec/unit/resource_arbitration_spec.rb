require_relative './_helper'

RSpec.describe Admission::ResourceArbitration do

  describe '#new' do

    it 'parses simple Symbol scope' do
      arbitration = Admission::ResourceArbitration.new nil, {scope: -1}, :req, :scope
      expect(arbitration).to have_inst_vars(
          person: nil,
          rules_index: -1,
          request: :req,
          resource: nil
      )
    end

    it 'parses type scope' do
      resource = Object.new
      arbitration = Admission::ResourceArbitration.new nil, {objects: -1}, :req, resource
      expect(arbitration).to have_inst_vars(
          person: nil,
          rules_index: -1,
          request: :req,
          resource: resource
      )
    end

    it 'parses nested type scope' do
      resource = Object.new
      arbitration = Admission::ResourceArbitration.new nil, {:'objects:vars' => -1}, :req, [resource, :vars]
      expect(arbitration).to have_inst_vars(
          person: nil,
          rules_index: -1,
          request: :req,
          resource: resource
      )
    end

  end

  describe 'RulesBuilder' do

    describe 'fails when given reserved action name' do

      let(:builder){
        builder = Admission::ResourceArbitration::RulesBuilder.new nil
        builder.instance_variable_set '@privilege', 'privilege'
        builder
      }

      it '#allow' do
        expect{ builder.allow '', :allow }.not_to raise_exception
        expect{ builder.allow '', Admission::ALL_ACTION }.to(
            raise_exception("reserved action name #{Admission::ALL_ACTION}")
        )
      end

      it '#forbid' do
        expect{ builder.forbid '', :forbid }.not_to raise_exception
        expect{ builder.forbid '', Admission::ALL_ACTION }.to(
            raise_exception("reserved action name #{Admission::ALL_ACTION}")
        )
      end

      it '#allow_resource' do
        expect{ builder.allow_resource :'', :allow_resource, &->{} }.not_to raise_exception
        expect{ builder.allow_resource :'', Admission::ALL_ACTION, &->{} }.to(
            raise_exception("reserved action name #{Admission::ALL_ACTION}")
        )
      end

    end

  end

end