module MiddleAges

  class Person

    attr_reader :name, :age, :sex, :residence
    attr_reader :privileges

    FEMALE            = 0
    MALE              = 1
    APACHE_HELICOPTER = 2

    def initialize name, age, sex, residence
      @name = name
      @age = age
      @sex = sex
      @residence = residence
    end

    def not_woman?
      @sex != FEMALE
    end

    def from_region? region
      residence.region == region
    end

    def is_child?
      age < 10
    end

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

  class VillageOrRegion

    def initialize value
      @value = value
    end

    def includes_village? village
      case @value
        when Village then village == @value
        when Region then village.region == @value
      end
    end

    def is_a_region? region
      @value.is_a?(Region) && @value == region
    end

  end

  # TODO
  # - context: false by default
  # - context always can be nil
  # - check inheritance doesn't break context type
  def self.privileges
    @privileges ||= Admission.define_privileges do
      privilege :human,    levels: %i[noble]
      privilege :vassal,                              context: Region
      privilege :priest,   levels: %i[bishop pope],   context: VillageOrRegion
      privilege :emperor,  inherits: %i[human priest]
      privilege :god
    end
  end

  def self.rules
    @rules ||= Admission.define_rules privileges do

      privilege :human do
        allow :enjoy, :life do
          no_woman? ? age < 60 : age < 65
        end
        allow :enjoy, :games, if: ->{ is_child? }
        allow_any :actions, if: :not_woman?
        forbid :actions, :literally_whatever
      end

      privilege :human, :noble do
        allow :enjoy, :life do
          no_woman? ? age < 62 : age < 67
        end
        allow :enjoy, :games
        allow_any :actions
      end

      privilege :vassal do
        allow_resource Person, :impose_corve, if: [ Person, :from_region? ]
        allow_resource [Region, :villages], :impose_levy,
            if: [ Region, :== ]
        allow_resource [Region, :villages], :impose_recruitment,
            if: -> (resource, context) { resource == context && resource.has_males? }
      end

      privilege :priest do
        # for the lolz, but needs to work
        allow :actions, :mary, if: ->{ :forbid }
        forbid :enjoy, :games
        allow Village, :perform_mass, resource: true,
            if: ->(resource, context) { context.includes_village? resource }
        allow Person, :forgive_sins, resource: true do |resource, context|
          context.includes_village? resource.residence
        end
      end

      privilege :bishop do
        allow_resource Region, :perform_mass,
            if: ->(resource, context) { context.is_a_region? resource }
      end

      privilege :pope do
        allow_resource Village, :perform_mass
        allow_resource Region, :perform_mass
      end

      privilege :emperor do
        allow_resource_crud Person, only: %i[index show destroy]
        allow :actions, :literally_whatever
        forbid Village, :perform_mass
        forbid :regions, :perform_mass
      end

      privilege :god do
        allow_resource_crud Person
      end

    end
  end

  module Index

    def records
      @records ||= {}
    end

    def [] name
      records[name] || (raise "no such record: #{self.class.name} - #{name}")
    end

  end

end
