require_relative '../spec_helper'

RSpec.describe Admission::Arbitration do

  describe 'RulesBuilder' do

    describe 'fails when given reserved action name' do

      let(:builder){
        builder = Admission::Arbitration::RulesBuilder.new nil
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

    end

  end

end