require_relative './middle_ages'

RSpec.describe 'middle_ages' do

  before(:context){ @privileges = [] }
  after{ @person = nil }
  after{ clear_privileges }

  def new_person age, sex, residence, name: 'test-person'
    MiddleAges::Person.new name, age, sex, residence
  end

  def set_person **attrs
    attrs = {
        age: 42,
        sex: :male,
        **attrs,
    }
    @person = new_person nil, nil, nil
    attrs.each{|attr, value| person.send "#{attr}=", value }
    person
  end
  attr_reader :person

  def clear_privileges
    @privileges.clear
  end

  def add_privilege name, grade=nil, region: nil
    name = MiddleAges::Privilege.produce_combined_name name, grade if grade
    privilege = MiddleAges.privileges.get nil, name, region
    @privileges.push privilege
    privilege
  end

  def set_privilege *args
    clear_privileges
    add_privilege *args
  end

  def admissible? *args
    person.privileges = @privileges
    @privileges.each{|privilege| privilege.person = person }
    person.admissible? *args
  end

  # sad times :-(
  it 'asserts women are not equal to men' do
    set_privilege :human

    set_person sex: :female
    expect(admissible? :be_self).to be(false)

    set_person sex: :who_cares
    expect(admissible? :be_self).to be(false)

    set_person
    expect(admissible? :be_self).to be(true)
  end

  it 'asserts women can live a bit longer' do
    set_privilege :human

    set_person sex: :female
    expect(admissible? :live_a_bit_more).to be(true)

    set_person
    expect(admissible? :live_a_bit_more).to be(true)

    set_person sex: :female, age: 46
    expect(admissible? :live_a_bit_more).to be(true)

    set_person age: 46
    expect(admissible? :live_a_bit_more).to be(false)

    set_person sex: :female, age: 56
    expect(admissible? :live_a_bit_more).to be(false)
  end

  it 'asserts only child can play' do
    set_privilege :human

    set_person
    expect(admissible? :enjoy_games).to be(false)

    set_person age: 9
    expect(admissible? :enjoy_games).to be(true)
  end

  it 'asserts regular folks cannot act fancy like nobles do' do
    set_privilege :human
    set_person
    expect(admissible? :act_fancy).to be(false)

    set_privilege :human, :noble
    expect(admissible? :act_fancy).to be(true)
  end

  it 'asserts no noble can be basic' do
    set_privilege :human
    set_person
    expect(admissible? :be_a_bit_basic).to be(true)

    set_privilege :human, :noble
    expect(admissible? :be_a_bit_basic).to be(false)
  end

  it 'asserts vassal can impose corvee on his subjects' do
    subject = new_person 12, :male, :moravia, name: 'subject'
    set_person

    set_privilege :vassal
    expect(admissible? :impose_corvee, subject).to be(false)

    set_privilege :vassal, region: :silesia
    expect(admissible? :impose_corvee, subject).to be(false)

    set_privilege :vassal, region: :moravia
    expect(admissible? :impose_corvee, subject).to be(true)
  end

  it 'asserts vassal can be rude to subjects' do
    set_person
    set_privilege :vassal

    subject = new_person 12, :male, :moravia, name: 'subject'
    expect(admissible? :frown_upon, subject).to be(true)
    expect(admissible? :frown_upon, :persons).to be(true)
  end

  it 'asserts vassal can impose a levy in his region' do
    set_person
    region = -> (region_name) { MiddleAges::Region.new region_name }
    village = -> (region_name) { [ region.(region_name), :villages ] }

    set_privilege :vassal
    expect(admissible? :impose_levy, village.(:silesia)).to be(false)

    set_privilege :vassal, region: region.(:moravia)
    expect(admissible? :impose_levy, village.(:silesia)).to be(false)

    set_privilege :vassal, region: region.(:silesia)
    expect(admissible? :impose_levy, village.(:silesia)).to be(true)

    set_privilege :vassal, region: region.(:nesselsdorf)
    expect(admissible? :impose_levy, village.(:nesselsdorf)).to be(false)
  end

  it 'assert vassal can impose a recruitment in his region' do
    set_person
    region = -> (region_name) { MiddleAges::Region.new region_name }
    village = -> (region_name) { [ region.(region_name), :villages ] }

    set_privilege :vassal
    expect(admissible? :impose_recruitment, village.(:silesia)).to be(false)

    set_privilege :vassal, region: region.(:moravia)
    expect(admissible? :impose_recruitment, village.(:silesia)).to be(false)

    set_privilege :vassal, region: region.(:silesia)
    expect(admissible? :impose_recruitment, village.(:silesia)).to be(true)
  end

end
