
fixtures = {

    nobody: [
        Person::FEMALE
    ],

    harambe: [
        Person::MALE#,
        # {all: 'harambe'}
    ],

    european_god: [
        Person::MALE#,
        # {czech: 'supernatural-primordial', taiwan: 'supernatural-god'}
    ]

}

privileges_data_reducer = -> (privileges_data) {
  privileges_data.to_a.reduce [] do |list, per_country_definition|
    country, privileges_names = per_country_definition
    raise "bad country #{country}" unless COUNTRIES.include? country
    privileges_names = [privileges_names] unless privileges_names.is_a? Array

    privileges = privileges_names.map do |name|
      privilege = Admission::Privilege.get_from_order PRIVILEGES_ORDER, *name.split('-')
      privilege.dup_with_context country
    end

    list + privileges
  end
}

Person::FIXTURES = ->(name) {
  sex, privileges = fixtures[name]
  person = Person.new name, sex
  person.instance_variable_set :@privileges, privileges_data_reducer.(privileges)
  person
}