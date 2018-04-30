
fixtures = {

    peasant_girl: [
        Person::FEMALE,
        []
    ],

    napoleon: [
        Person::MALE,
        []
        # {all: 'harambe'}
    ],

    franz_joseph: [
        Person::MALE,
        [:czech, :australia]
        # {czech: 'supernatural-primordial', taiwan: 'supernatural-god'}
    ]

}

privileges_data_reducer = -> (privileges_data) {
  privileges_data.to_a.reduce [] do |list, per_country_definition|
    country, privileges_names = per_country_definition
    raise "bad country #{country}" unless COUNTRIES.include? country
    privileges_names = [privileges_names] unless privileges_names.is_a? Array

    privileges = privileges_names.map do |name|
      privilege = PRIVILEGES_ORDER.get *Admission::Privilege.split_text_key(name)
      privilege.dup_with_context country
    end

    list + privileges
  end
}

Person::FIXTURES = ->(name) {
  *attrs, privileges = fixtures[name]
  person = Person.new name, *attrs
  person.instance_variable_set :@privileges, privileges_data_reducer.(privileges)
  person
}