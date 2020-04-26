module MiddleAges

  class Person

    attr_reader :name, :sex, :origin
    attr_reader :privileges

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

    # def person
    #   self
    # end

    # def allow_possession_change? _, country
    #   origin.include? country
    # end

  end

  class Region

    attr_reader :name, :lord, :bishop

    def initialize name, lord, bishop
      @name = name
      @lord = lord
      @bishop = bishop
    end

  end

  class Village

    attr_reader :name, :region

    def initialize name, region
      @name = name
      @region = region
    end

  end

  def self.privileges
    @privileges ||= Admission.define_privileges do
      privilege :human,    levels: %i[noble]
      privilege :vassal
      privilege :priest,   levels: %i[bishop pope]
      privilege :emperor,  inherits: %i[human priest]
      privilege :god
    end
  end

  def self.rules
    @rules ||= Admission.define_rules privileges do

      privilege :human do
        allow_any :actions, if: ->(_){ not_woman? }
      end

    end
  end

  # RESOURCES_RULES = Admission::ResourceArbitration.define_rules_for ORDER do
  #
  #   # Rules for `allow_all` & inheriting `:forbidden`
  #
  #   privilege :human do
  #     allow_all :actions, ->{ not_woman? }
  #     allow :actions
  #
  #     # forbid :actions, :raise_taxes
  #     # forbid :actions, :impose_corvee
  #     # forbid :actions, :impose_draft
  #     forbid :actions, :act_as_god
  #     forbid :actions, :choose_spouse
  #   end
  #
  #   privilege :human, :count do
  #     allow_all :actions do |country|
  #       origin.include? country
  #     end
  #     allow :actions, :impose_corvee do |country|
  #       origin.include? country
  #     end
  #   end
  #
  #   privilege :human, :king do
  #     allow_all :actions
  #     allow :actions, :raise_taxes
  #   end
  #
  #   privilege :vassal, :lord do
  #     allow :actions, :impose_draft
  #   end
  #
  #   privilege :emperor do
  #     allow :actions, :act_as_god
  #   end
  #
  #   # Rules for `allow_resource` scoping & inheritance
  #
  #   privilege :vassal do
  #
  #     allow_resource Person, :show do |person, _|
  #       self == person
  #     end
  #
  #     allow :persons, :index do |country|
  #       origin.include? country
  #     end
  #
  #   end
  #
  #   privilege :vassal, :lord do
  #
  #     # this is weird but must be valid
  #     allow_resource(Person, :show){|*_| true }
  #
  #     allow_resource Person, %i[update] do |person, country|
  #       allowance = origin.include? country
  #       next allowance unless person
  #
  #       allowance && person.origin.include?(country)
  #     end
  #
  #     allow_resource Person, :destroy do |person, country|
  #       person.origin.include?(country) &&
  #           person.sex != Person::APACHE_HELICOPTER
  #     end
  #
  #     allow Admission::ResourceArbitration.nested_scope(Person, :possessions), :index
  #     allow_resource [Person, :possessions], :update, rule: :allow_possession_change?
  #
  #   end
  #
  # end

  module Index

    def records
      @records ||= {}
    end

    def [] name
      records[name] || (raise "no such record: #{self.class.name} - #{name}")
    end

  end

end
