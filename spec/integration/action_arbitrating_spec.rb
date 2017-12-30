require_relative '../spec_helper'

RSpec.describe 'actions_arbitrating' do

  def arbitration request, context=nil
    person = Person.new 'person', Person::MALE, [:czech]
    arbitration = Admission::Arbitration.new person, ACTIONS_RULES, request
    arbitration.prepare_sitting context
    arbitration
  end

  def privilege *args, context: nil
    p = Admission::Privilege.get_from_order PRIVILEGES_ORDER, *args
    p = p.dup_with_context context if context
    p
  end

  def rule request, privilege
    arbitration(request, privilege.context).rule_per_privilege privilege
  end

  it 'allows human to do anything' do
    expect(
        rule :anything, privilege(:human)
    ).to eql(true)
  end

  it 'disallows woman to do anything' do
    person = Person.new 'person', Person::FEMALE, [:czech]
    arbitration = Admission::Arbitration.new person, ACTIONS_RULES, :anything
    arbitration.prepare_sitting
    expect(
        arbitration.rule_per_privilege privilege(:human)
    ).to eql(false)
  end

  it 'allow woman-count to do anything in her country' do
    person = Person.new 'person', Person::FEMALE, [:czech]
    arbitration = Admission::Arbitration.new person, ACTIONS_RULES, :anything
    arbitration.prepare_sitting :czech
    expect(
        arbitration.rule_per_privilege privilege(:human, :count, context: :czech)
    ).to eql(true)
  end

  it 'allows only king to raise taxes' do
    expect(
        rule :raise_taxes, privilege(:human)
    ).to eql(:forbidden)

    expect(
        rule :raise_taxes, privilege(:human, :count)
    ).to eql(:forbidden)

    expect(
        rule :raise_taxes, privilege(:human, :king)
    ).to eql(true)
  end

  it 'allows count and king to impose corvee in his countries' do
    expect(
        rule :impose_corvee,
            privilege(:human, :count, context: :czech)
    ).to eql(true)

    expect(
        rule :impose_corvee,
            privilege(:human, :king, context: :czech)
    ).to eql(true)
  end

  it 'forbids count and king to impose corvee outside his countries' do
    expect(
        rule :impose_corvee,
            privilege(:human, :count, context: :taiwan)
    ).to eql(:forbidden)

    expect(
        rule :impose_corvee,
            privilege(:human, :king, context: :taiwan)
    ).to eql(:forbidden)
  end

  it 'forbids any human to impose a draft' do
    expect(
        rule :impose_draft, privilege(:human)
    ).to eql(:forbidden)

    expect(
        rule :impose_draft, privilege(:human, :count)
    ).to eql(:forbidden)

    expect(
        rule :impose_draft, privilege(:human, :king)
    ).to eql(:forbidden)
  end

  it 'allows lord to impose draft' do
    expect(
        rule :impose_draft,
            privilege(:vassal, :lord)
    ).to eql(true)
  end

  it 'forbids emperor to impose draft because of inheritance' do
    expect(
        rule :impose_draft,
            privilege(:emperor)
    ).to eql(:forbidden)
  end

  it 'allows emperor to act as god' do
    expect(
        rule :act_as_god,
            privilege(:emperor)
    ).to eql(true)
  end

end