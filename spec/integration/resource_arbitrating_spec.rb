require_relative '../spec_helper'

RSpec.describe 'resources_arbitrating' do

  let(:person){ Person.new 'person', Person::MALE, [:czech] }
  let(:female){ Person.new 'female', Person::FEMALE, [:czech] }

  def arbitration scope, action, context=nil
    arbitration = Admission::ResourceArbitration.new person, RESOURCE_RULES, action, scope
    arbitration.prepare_sitting context
    arbitration
  end

  def privilege *args, context: nil
    p = PRIVILEGES_ORDER.get *args
    p = p.dup_with_context context if context
    p
  end

  def actions_rule action, privilege
    arbitration(:actions, action, privilege.context).rule_per_privilege privilege
  end

  def rule scope, action, privilege
    arbitration(scope, action, privilege.context).rule_per_privilege privilege
  end

  describe 'actions scope' do

    it 'allows human to do anything' do
      expect(
          actions_rule :anything, privilege(:human)
      ).to eql(true)
    end

    it 'disallows woman to do anything' do
      arbitration = Admission::ResourceArbitration.new female, RESOURCE_RULES,
          :anything, :actions
      arbitration.prepare_sitting
      expect(
          arbitration.rule_per_privilege privilege(:human)
      ).to eql(false)
    end

    it 'allow woman-count to do anything in her country' do
      arbitration = Admission::ResourceArbitration.new female, RESOURCE_RULES,
          :anything, :actions
      arbitration.prepare_sitting :czech
      expect(
          arbitration.rule_per_privilege privilege(:human, :count, context: :czech)
      ).to eql(true)
    end

    it 'allows only king to raise taxes' do
      expect(
          actions_rule :raise_taxes, privilege(:human)
      ).to eql(:forbidden)

      expect(
          actions_rule :raise_taxes, privilege(:human, :count)
      ).to eql(:forbidden)

      expect(
          actions_rule :raise_taxes, privilege(:human, :king)
      ).to eql(true)
    end

    it 'allows count and king to impose corvee in his countries' do
      expect(
          actions_rule :impose_corvee,
              privilege(:human, :count, context: :czech)
      ).to eql(true)

      expect(
          actions_rule :impose_corvee,
              privilege(:human, :king, context: :czech)
      ).to eql(true)
    end

    it 'forbids count and king to impose corvee outside his countries' do
      expect(
          actions_rule :impose_corvee,
              privilege(:human, :count, context: :taiwan)
      ).to eql(:forbidden)

      expect(
          actions_rule :impose_corvee,
              privilege(:human, :king, context: :taiwan)
      ).to eql(:forbidden)
    end

    it 'forbids any human to impose a draft' do
      expect(
          actions_rule :impose_draft, privilege(:human)
      ).to eql(:forbidden)

      expect(
          actions_rule :impose_draft, privilege(:human, :count)
      ).to eql(:forbidden)

      expect(
          actions_rule :impose_draft, privilege(:human, :king)
      ).to eql(:forbidden)
    end

    it 'allows lord to impose draft' do
      expect(
          actions_rule :impose_draft, privilege(:vassal, :lord)
      ).to eql(true)
    end

    it 'forbids emperor to impose draft because of inheritance' do
      expect(
          actions_rule :impose_draft, privilege(:emperor)
      ).to eql(:forbidden)
    end

    it 'allows emperor to act as god' do
      expect(
          actions_rule :act_as_god, privilege(:emperor)
      ).to eql(true)
    end

  end

  describe 'resources scope' do

    it 'allows vassal to see only himself' do
      expect(
          rule person, :show, privilege(:vassal)
      ).to eql(true)

      person = Person.new 'person', Person::FEMALE, [:czech]
      expect(
          rule person, :show, privilege(:vassal)
      ).to eql(false)
    end

    it 'passes nil as argument if resource-arbiter accessed by name-scope' do
      expect{
        rule :persons, :show, privilege(:vassal)
      }.to raise_error('person is nil')
    end

    it 'allows vassal to list persons only per his countries' do
      expect(
          rule :persons, :index, privilege(:vassal, context: :czech)
      ).to eql(true)

      expect(
          rule :persons, :index, privilege(:vassal, context: :taiwan)
      ).to eql(false)
    end

    it 'allows access scope-arbiter by resource' do
      expect(
          rule person, :index, privilege(:vassal, context: :czech)
      ).to eql(true)
    end

    it 'allows lord to see any person' do
      expect(
          rule person, :show, privilege(:vassal, :lord)
      ).to eql(true)

      expect(
          rule female, :show, privilege(:vassal, :lord)
      ).to eql(true)
    end

    it 'allows lord to list persons from his country' do
      expect(
          rule person, :index, privilege(:vassal, context: :czech)
      ).to eql(true)

      expect(
          rule :persons, :index, privilege(:vassal, context: :czech)
      ).to eql(true)

      expect(
          rule person, :index, privilege(:vassal, context: :taiwan)
      ).to eql(false)
    end

    it 'allows lord to update person that is from his country' do
      expect(
          rule female, :update,
              privilege(:vassal, :lord, context: :czech)
      ).to eql(true)

      expect(
          rule female, :update, privilege(:vassal, :lord)
      ).to eql(false)
    end

    it 'disallows lord to update person not from his country' do
      female = Person.new 'person', Person::FEMALE, [:taiwan]

      expect(
          rule female, :update,
              privilege(:vassal, :lord, context: :czech)
      ).to eql(false)

      expect(
          rule female, :update,
              privilege(:vassal, :lord, context: :taiwan)
      ).to eql(false)
    end

    it 'ensures lord cannot update person accessing him by scope-name' do
      expect(
          rule :persons, :update, privilege(:vassal, :lord)
      ).to eql(false)
    end

    it 'disallows vassal to update person' do
      expect(
          rule person, :update, privilege(:vassal, context: :czech)
      ).to eql(false)
    end

    it 'allows lord to destroy person from his country' do
      female = Person.new 'person', Person::FEMALE, [:taiwan]

      expect(
          rule person, :destroy,
              privilege(:vassal, :lord, context: :czech)
      ).to eql(true)

      expect(
          rule female, :destroy,
              privilege(:vassal, :lord, context: :czech)
      ).to eql(false)
    end

    it 'disallows lord to destroy apache helicopter' do
      helicopter = Person.new 'person', Person::APACHE_HELICOPTER, [:czech]
      expect(
          rule helicopter, :destroy,
              privilege(:vassal, :lord, context: :czech)
      ).to eql(false)
    end

  end

  describe 'nested resource scope' do

    it 'allows any lord to list others possessions' do
      expect(
          rule [person, :possessions], :index, privilege(:vassal, :lord)
      ).to eql(true)

      expect(
          rule [person, :possessions], :index, privilege(:vassal)
      ).to eql(false)
    end

    it 'allows lord to update possessions of his country' do
      expect(
          rule [person, :possessions], :update, privilege(:vassal, :lord)
      ).to eql(false)

      expect(
          rule [person, :possessions], :update,
              privilege(:vassal, :lord, context: :czech)
      ).to eql(true)

      expect(
          rule [person, :possessions], :update,
              privilege(:vassal, :lord, context: :taiwan)
      ).to eql(false)

      # in other way, test rule method
      expect(person).to receive(:allow_possession_change?).
              with(person, :taiwan).
              and_return(true)
      expect(
          rule [person, :possessions], :update,
              privilege(:vassal, :lord, context: :taiwan)
      ).to eql(true)
    end

  end

end