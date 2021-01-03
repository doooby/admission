require_relative './middle_ages'

RSpec.describe 'middle_ages' do

  before(:context){ @privileges = [] }
  after{ @person = nil }
  after{ clear_privileges }

  def new_person age, sex, residence, name: 'test-person'
    MiddleAges::Person.new name, age, sex, residence
  end

  def set_person person, **modifications
    @person = case person
      when :default then new_person 42, :male, nil
      else person
    end

    modifications.each do |attr, value|
      @person.send "#{attr}=", value
    end

    @person
  end
  attr_reader :person

  def clear_privileges
    @privileges.clear
  end

  def add_privilege name
    privilege = MiddleAges.privileges.get person, name
    @privileges.push privilege
    privilege
  end

  def admissible? action
    person.privileges = @privileges
    person.admissible? action
  end

  # sad times :-(
  it 'asserts women are not equal to men' do
    add_privilege :human

    set_person :default, sex: :female
    expect(admissible? :be_herself).to be(false)

    set_person :default, sex: :who_cares
    expect(admissible? :be_self).to be(false)

    set_person :default
    expect(admissible? :be_himself).to be(true)
  end

end
