

PRIVILEGES_ORDER = Admission::Privilege.define_order do
  privilege :vassal,   levels: %i[lord]
  privilege :human,    levels: %i[count king]
  privilege :emperor,  inherits: %i[vassal human]
end


ACTIONS_RULES = Admission::Arbitration.define_rules PRIVILEGES_ORDER do

  privilege :human do
    allow_all{ not_woman? }
    forbid :raise_taxes
    forbid :impose_corvee

    forbid :impose_draft
    forbid :act_as_god
  end

  privilege :human, :count do
    allow_all do |country|
      countries.include? country
    end
    allow :impose_corvee do |country|
      countries.include? country
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


RESOURCE_RULES = Admission::ResourceArbitration.define_rules PRIVILEGES_ORDER do

  # `allow_all` & inheriting `:forbidden`

  privilege :human do
    allow_all(:actions){ not_woman? }
    forbid :actions, :raise_taxes
    forbid :actions, :impose_corvee

    forbid :actions, :impose_draft
    forbid :actions, :act_as_god
  end

  privilege :human, :count do
    allow_all :actions do |country|
      countries.include? country
    end
    allow :actions, :impose_corvee do |country|
      countries.include? country
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

  # `allow_resource` scoping & inheritance

  privilege :vassal do

    allow_resource Person, :show do |person, *|
      raise 'person is nil' unless person
      self == person
    end

    allow :persons, :index do |country|
      countries.include? country
    end

  end

  privilege :vassal, :lord do

    allow_resource(Person, :show){ true }

    allow_resource Person, %i[index update] do |person, country|
      allowance = countries.include? country
      next allowance unless person

      allowance && person.countries.include?(country)
    end

    allow_resource Person, :destroy do |person, country|
      person.countries.include?(country) &&
          person.sex != Person::APACHE_HELICOPTER
    end

    allow Admission::ResourceArbitration.nested_scope(Person, :possessions), :index
    allow_resource [Person, :possessions], :update do |person, country|
      person.countries.include?(country)
    end

  end

end