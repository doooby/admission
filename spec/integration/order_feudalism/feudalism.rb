module Feudalism

  class Person

    attr_reader :name, :sex, :origin
    attr_reader :privileges, :rules

    FEMALE            = 0
    MALE              = 1
    APACHE_HELICOPTER = 2

    def initialize name, sex, origin
      @name = name
      @sex = sex
      @origin = origin
    end

    def not_woman?
      @sex != FEMALE
    end

    def person
      self
    end

    def allow_possession_change? _, country
      origin.include? country
    end

  end

  ORDER = Admission.define_privileges do
    privilege :vassal,   levels: %i[lord]
    privilege :human,    levels: %i[count king]
    privilege :emperor,  inherits: %i[vassal human]
  end

  ACTIONS_RULES = Admission::Arbitration.define_rules_for ORDER do

    privilege :human do
      allow_all{ not_woman? }
      forbid :raise_taxes
      forbid :impose_corvee

      forbid :impose_draft
      forbid :act_as_god
    end

    privilege :human, :count do
      allow_all do |country|

        origin.include? country
      end
      allow :impose_corvee do |country|
        origin.include? country
      end
    end

    privilege :human, :king do
      allow_all
      allow :raise_taxes
    end

    privilege :vassal, :lord do
      allow :impose_draft
    end

    privilege :emperor do
      allow :act_as_god
    end

  end

  RESOURCES_RULES = Admission::ResourceArbitration.define_rules_for ORDER do

    # Rules for `allow_all` & inheriting `:forbidden`

    privilege :human do
      allow_all(:actions){ not_woman? }
      forbid :actions, :raise_taxes
      forbid :actions, :impose_corvee

      forbid :actions, :impose_draft
      forbid :actions, :act_as_god
    end

    privilege :human, :count do
      allow_all :actions do |country|
        origin.include? country
      end
      allow :actions, :impose_corvee do |country|
        origin.include? country
      end
    end

    privilege :human, :king do
      allow_all :actions
      allow :actions, :raise_taxes
    end

    privilege :vassal, :lord do
      allow :actions, :impose_draft
    end

    privilege :emperor do
      allow :actions, :act_as_god
    end

    # Rules for `allow_resource` scoping & inheritance

    privilege :vassal do

      allow_resource Person, :show do |person, _|
        raise 'person is nil' unless person
        self == person
      end

      allow :persons, :index do |country|
        origin.include? country
      end

    end

    privilege :vassal, :lord do

      # this is weird but must be valid
      allow_resource(Person, :show){|*_| true }

      allow_resource Person, %i[update] do |person, country|
        allowance = origin.include? country
        next allowance unless person

        allowance && person.origin.include?(country)
      end

      allow_resource Person, :destroy do |person, country|
        person.origin.include?(country) &&
            person.sex != Person::APACHE_HELICOPTER
      end

      allow Admission::ResourceArbitration.nested_scope(Person, :possessions), :index
      allow_resource [Person, :possessions], :update, rule: :allow_possession_change?

    end

  end

end
