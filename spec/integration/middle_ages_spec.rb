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

  def add_privilege name, grade=nil
    name = MiddleAges::Privilege.produce_combined_name name, grade if grade
    privilege = MiddleAges.privileges.get nil, name
    @privileges.push privilege
    privilege
  end

  def admissible? action
    person.privileges = @privileges
    @privileges.each{|privilege| privilege.person = person }
    person.admissible? action
  end

  # sad times :-(
  it 'asserts women are not equal to men' do
    add_privilege :human

    set_person :default, sex: :female
    expect(admissible? :be_self).to be(false)

    set_person :default, sex: :who_cares
    expect(admissible? :be_self).to be(false)

    set_person :default
    expect(admissible? :be_self).to be(true)
  end

  it 'asserts women can live a bit longer' do
    add_privilege :human

    set_person :default, sex: :female
    expect(admissible? :live_a_bit_more).to be(true)

    set_person :default
    expect(admissible? :live_a_bit_more).to be(true)

    set_person :default, sex: :female, age: 46
    expect(admissible? :live_a_bit_more).to be(true)

    set_person :default, age: 46
    expect(admissible? :live_a_bit_more).to be(false)

    set_person :default, sex: :female, age: 56
    expect(admissible? :live_a_bit_more).to be(false)
  end

  it 'asserts only child can play' do
    add_privilege :human

    set_person :default
    expect(admissible? :enjoy_games).to be(false)

    set_person :default, age: 9
    expect(admissible? :enjoy_games).to be(true)
  end

  it 'asserts regular folks cannot act fancy like nobles do' do
    add_privilege :human
    set_person :default
    expect(admissible? :act_fancy).to be(false)

    clear_privileges
    add_privilege :human, :noble
    expect(admissible? :act_fancy).to be(true)
  end

  it 'asserts no noble can be basic' do
    add_privilege :human
    set_person :default
    expect(admissible? :be_a_bit_basic).to be(true)

    clear_privileges
    add_privilege :human, :noble
    expect(admissible? :be_a_bit_basic).to be(false)
  end

end
