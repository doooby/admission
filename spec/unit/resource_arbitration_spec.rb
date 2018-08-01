require_relative '../spec_helper'

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

    let(:builder){
      builder = Admission::ResourceArbitration::RulesBuilder.new nil
      builder.instance_variable_set '@privilege', 'privilege'
      builder
    }

    describe 'fails when given reserved action name' do

      it '#allow' do
        expect{ builder.allow :scope, :allow }.not_to raise_exception
        expect{ builder.allow :scope, Admission::ALL_ACTION }.to(
            raise_exception("reserved action name #{Admission::ALL_ACTION}")
        )
      end

      it '#forbid' do
        expect{ builder.forbid :scope, :forbid }.not_to raise_exception
        expect{ builder.forbid :scope, Admission::ALL_ACTION }.to(
            raise_exception("reserved action name #{Admission::ALL_ACTION}")
        )
      end

      it '#allow_resource' do
        expect{ builder.allow_resource :scope, :allow_resource, &->{} }.not_to raise_exception
        expect{ builder.allow_resource :scope, Admission::ALL_ACTION, &->{} }.to(
            raise_exception("reserved action name #{Admission::ALL_ACTION}")
        )
      end

    end

    describe 'scope normalization for' do

      def test_normal_scopes
        [
            [:scope           , :scope],
            [[:parent, :child], :'parent:child'],
            [String           , :strings]
        ].each do |passed_argument, expected_scope|
          yield passed_argument
          expect(builder.rules.last[:scope]).to eq(expected_scope)
        end

        expect{
          yield nil
        }.to raise_exception('invalid scope')
      end

      it '#allow' do
        test_normal_scopes do |scope|
          builder.allow scope, :act
        end
      end

      it '#allow_all' do
        test_normal_scopes do |scope|
          builder.allow_all scope
        end
      end

      it '#forbid' do
        test_normal_scopes do |scope|
          builder.forbid scope, :act
        end
      end

      it '#allow_resource' do
        test_normal_scopes do |scope|
          builder.allow_resource(scope, :act){}
        end
      end

    end

  end

end