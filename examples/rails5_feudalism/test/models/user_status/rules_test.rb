require 'test_helper'

class UserStatus::RulesTest < ActiveSupport::TestCase

  ALL_PRIVILEGES = []
  Person::COUNTRIES.each do |country|
    UserStatus.privileges_list.each do |privilege|
      ALL_PRIVILEGES << privilege.dup_with_context(country)
    end
  end
  ALL_PRIVILEGES.freeze

  def user_from *countries
    countries = countries.flatten
    countries.each do |country|
      yield User.new(person: Person.new(country: country))
    end
  end

  test 'persons:possessions scope - index' do
    user_from Person::COUNTRIES do |user|
      ALL_PRIVILEGES.each do |privilege|
        assert_allows user, privilege, :index, :'persons:possessions'
      end
    end
  end

  test 'persons:possessions scope - create' do
    cons, pros = ALL_PRIVILEGES.partition{|p| p.text_key == 'human'}

    user_from Person::COUNTRIES do |user|
      pros.each do |privilege|
        assert_allows user, privilege, :create, :'persons:possessions'
      end

      cons.each do |privilege|
        assert_not_allows user, privilege, :create, :'persons:possessions'
      end
    end
  end

  test 'persons:possessions scope - update' do
    cons, pros = ALL_PRIVILEGES.partition{|p| p.text_key == 'human'}

    user_from Person::COUNTRIES do |user|
      same_person = user.person
      other_person = Person.new country: user.person.country

      ALL_PRIVILEGES.each do |privilege|
        assert_not_allows user, privilege, :update, :'persons:possessions'
        assert_not_allows user, privilege, :update, [other_person, :possessions]
      end

      pros.each do |privilege|
        assert_allows user, privilege, :update, [same_person, :possessions]
      end

      cons.each do |privilege|
        assert_not_allows user, privilege, :update, [same_person, :possessions]
      end
    end
  end

  test 'persons:possessions scope - impound' do
    pros, cons = ALL_PRIVILEGES.partition{|p| p.text_key == 'lord'}

    user_from Person::COUNTRIES do |user|
      other_country_person = Person.new country: 'Austria'

      ALL_PRIVILEGES.each do |privilege|
        assert_not_allows user, privilege, :impound, :'persons:possessions'
        assert_not_allows user, privilege, :impound, [other_country_person, :possessions]
      end

      pros.each do |privilege|
        same_country_person = Person.new country: privilege.country
        assert_allows user, privilege, :impound, [same_country_person, :possessions]
      end
      cons.each do |privilege|
        same_country_person = Person.new country: privilege.country
        assert_not_allows user, privilege, :impound, [same_country_person, :possessions]
      end
    end
  end

  test 'traits scope - index' do
    user_from Person::COUNTRIES do |user|
      ALL_PRIVILEGES.each do |privilege|
        assert_allows user, privilege, :index, :traits
      end
    end
  end

  test 'traits scope - update' do
    human, others = ALL_PRIVILEGES.partition{|p| p.text_key == 'human'}
    lord_duke, other_humans = others.partition{|p| p.name == 'lord' || p.name == 'duke'}

    user_from Person::COUNTRIES do |user|
      same_person_trait = Trait.new person: user.person
      other_person_trait = Trait.new person: Person.new(country: user.person.country)
      other_country_trait = Trait.new person: Person.new(country: 'Austria')

      ALL_PRIVILEGES.each do |privilege|
        assert_not_allows user, privilege, :update, :'traits'
        assert_not_allows user, privilege, :update, other_country_trait
      end

      human.each do |privilege|
        assert_not_allows user, privilege, :update, same_person_trait
        assert_not_allows user, privilege, :update, other_person_trait
      end

      other_humans.each do |privilege|
        assert_allows user, privilege, :update, same_person_trait
        assert_not_allows user, privilege, :update, other_person_trait
      end

      lord_duke.each do |privilege|
        assert_allows user, privilege, :update, other_person_trait
      end
    end
  end

  def assert_allows user, privilege, action, resource
    arbitration = Admission::ResourceArbitration.new user, UserStatus.rules, action, resource
    arbitration.prepare_sitting privilege.context
    assert arbitration.rule_per_privilege(privilege).eql?(true), ->{
      'Not allowed user from %s having privilege %s(%s) to %s over %s' % [
          user.person.country,
          privilege.text_key,
          privilege.country,
          action,
          arbitration.scope_and_resource(resource).first
      ]
    }
  end

  def assert_not_allows user, privilege, action, resource
    arbitration = Admission::ResourceArbitration.new user, UserStatus.rules, action, resource
    arbitration.prepare_sitting privilege.context
    assert_not arbitration.rule_per_privilege(privilege).eql?(true), ->{
      'Allowed user from %s having privilege %s(%s) to %s over %s' % [
          user.person.country,
          privilege.text_key,
          privilege.country,
          action,
          arbitration.scope_and_resource(resource).first
      ]
    }
  end

end