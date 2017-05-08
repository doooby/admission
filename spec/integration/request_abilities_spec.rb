require_relative '_helper'

RSpec.describe 'request_abilities' do

  def arbitration person_name, request, context=nil
    person = Person::FIXTURES[person_name]
    person.instance_variable_set :@ability_rules, REQUEST_ABILITIES
    arbitration = Admission::RequestArbitration.new person, request
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

  describe '#new' do



  end

  describe 'precedence fo forbidden over all' do

    it 'allow harambe anything except to live' do
      expect(
          rule :all, :harambe, privilege(:harambe)
      ).to eql(true)

      expect(
          rule :to_live, :harambe, privilege(:harambe)
      ).to eql(:forbidden)
    end

    it 'god can rule, only in europe' do
      expect(
          rule :rule_over_people, :european_god,
              privilege(:supernatural, :god, context: [:czech])
      ).to eql(true)

      expect(
          rule :rule_over_people, :european_god,
              privilege(:supernatural, :god, context: [:taiwan])
      ).to eql(false)
    end

    it 'no level of supernatural can be proven' do
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

    it 'forbidden precendece while inherited' do
      expect(
        rule :to_live, :harambe,
            privilege(:uber_harambe)
      ).to eql(:forbidden)
    end

  end

end