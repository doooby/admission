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

  def rule person_name, request, privilege
    arbitration(person_name, request, privilege.context).rule_per_privilege privilege
  end

  describe '#new' do



  end

  describe 'precedence fo forbidden over all' do

    it 'allow harambe anything except to live' do
      expect(
          rule :harambe, :all, privilege(:harambe)
      ).to eql(true)

      expect(
          rule :harambe, :to_live, privilege(:harambe)
      ).to eql(false)
    end

    it 'god can rule, only in europe' do
      expect(
          rule :european_god, :rule_over_people,
              privilege(:supernatural, :god, context: [:czech])
      ).to eql(true)

      expect(
          rule :european_god, :rule_over_people,
              privilege(:supernatural, :god, context: [:taiwan])
      ).to eql(false)
    end

  end

end