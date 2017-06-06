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

end