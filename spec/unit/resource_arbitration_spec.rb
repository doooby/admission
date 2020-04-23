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

  describe '#make_decision' do

    let(:arbitration){
      Admission::ResourceArbitration.new nil, {}, :req, :scope
    }

    it 'uses #process_proc_decision' do
      decision = ->{}
      expect(arbitration).to receive(:process_proc_decision).with(decision)
      arbitration.make_decision(
          {a: decision},
          :a
      )
    end

    it 'uses #process_method_decision' do
      decision = :some_method
      expect(arbitration).to receive(:process_method_decision).with(decision)
      arbitration.instance_variable_set '@resource', 'res'
      arbitration.make_decision(
          {a: decision},
          :a
      )
    end

  end

  describe '#process_method_decision'

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

    describe 'resource block marking' do

      it 'non-res reuse' do
        block = ->{}
        expect{ builder.allow :scope, :read, &block }.not_to raise_exception
        expect{ builder.allow :scope, :write, &block }.not_to raise_exception
      end

      it 'cannot reuse non-res as res' do
        block = ->{}
        expect{ builder.allow :scope, :read, &block }.not_to raise_exception
        expect{ builder.allow_resource :books, :write, &block }.to(
            raise_exception(/already non-resource arbiter$/)
        )
      end

      it 'res reuse' do
        block = ->{}
        expect{ builder.allow_resource :books, :read, &block }.not_to raise_exception
        expect{ builder.allow_resource :books, :write, &block }.not_to raise_exception
      end

      it 'cannot reuse res as non-res' do
        block = ->{}
        expect{ builder.allow_resource :books, :read, &block }.not_to raise_exception
        expect{ builder.allow :scope, :write, &block }.to(
            raise_exception(/already resource arbiter$/)
        )
      end

    end

  end

end