require_relative '_helper'

RSpec.describe 'actions_arbitrating' do

  def arbitration person_name, request, context=nil
    person = Person::FIXTURES[person_name]
    person.instance_variable_set :@rules, ACTIONS_RULES
    arbitration = Admission::Arbitration.new person, request
    arbitration.prepare_sitting *context
    arbitration
  end

  def privilege *args, context: nil
    p = Admission::Privilege.get_from_order PRIVILEGES_ORDER, *args
    p = p.dup_with_context context if context
    p
  end

  def rule request, person_name, privilege
    arbitration(person_name, request, privilege.context).rule_per_privilege privilege
  end

  it 'allows harambe anything' do
    expect(
        rule :all, :harambe, privilege(:harambe)
    ).to eql(true)
  end

  it 'forbids harambe to live' do
    expect(
        rule :to_live, :harambe, privilege(:harambe)
    ).to eql(:forbidden)
  end

  it 'allows the god to rule in europe' do
    expect(
        rule :rule_over_people, :european_god,
            privilege(:supernatural, :god, context: [:czech])
    ).to eql(true)
  end

  it 'disallows the god to rule outside europe' do
    expect(
        rule :rule_over_people, :european_god,
            privilege(:supernatural, :god, context: [:taiwan])
    ).to eql(false)
  end

  it 'forbids any level of supernatural to be proven' do
    expect(
        rule :to_be_proven, :european_god,
            privilege(:supernatural)
    ).to eql(:forbidden)

    expect(
        rule :to_be_proven, :european_god,
            privilege(:supernatural, :god, context: [:czech])
    ).to eql(:forbidden)

    expect(
        rule :to_be_proven, :european_god,
            privilege(:supernatural, :primordial)
    ).to eql(:forbidden)
  end

  it 'forbids uber-harambe to live because of inheritance' do
    expect(
        rule :to_live, :harambe,
            privilege(:uber_harambe)
    ).to eql(:forbidden)
  end

end