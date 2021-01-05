module MiddleAges

  # class Person2
  #   include Admission::PersonWithStatus
  #
  #   attr_reader :name, :age, :sex, :residence
  #   attr_reader :privileges
  #
  #   FEMALE            = 0
  #   MALE              = 1
  #   APACHE_HELICOPTER = 2
  #
  #   def initialize name, age, sex, residence
  #     @name = name
  #     @age = age
  #     @sex = sex
  #     @residence = residence
  #   end
  #
  #   def is_child?
  #     age < 10
  #   end
  #
  #   # Privilege.class_evaluate do
  #   #
  #   #   attr_reader :region
  #   #   delegate_to_person :is_child?
  #   #
  #   #   def self.bound_dup region, *args
  #   #     privilege = super *args
  #   #     privilege.instane_variable_set :@region, region
  #   #     privilege
  #   #   end
  #   #
  #   #   def apply_to_region? region
  #   #     person.residence == region
  #   #   end
  #   #
  #   #   def not_woman?
  #   #     person.sex != Person::FEMALE
  #   #   end
  #   #
  #   # end
  #
  # end

  # class Region
  #
  #   attr_reader :id, :designation, :lord, :bishop
  #
  #   def initialize designation, lord, bishop
  #     @id = designation.to_s.freeze
  #     @designation = designation.to_s.freeze
  #     @lord = lord
  #     @bishop = bishop
  #     freeze
  #   end
  #
  #   def self.parse designation
  #     designation.to_s.chars.each_slice(2).map(&:join).to_a
  #   end
  #
  # end

  # TODO
  # - context: false by default
  # - context always can be nil
  # - check inheritance doesn't break context type
  def self.privileges
    @privileges ||= Admission.define_privileges klass: Privilege do
      privilege :human,    grades: %i[noble]
      privilege :vassal
      privilege :priest,   grades: %i[bishop pope]
      privilege :emperor,  inherits: %i[human-noble priest-pope]
      privilege :god
    end
  end

  def self.rules
    @rules ||= Admission.define_rules privileges do

      # is_from_users_region = -> (resource, region) { resource.from_region? region }

      privilege :human do
        allow :live_a_bit_more do
          person.male? ? age < 45 : age < 50
        end
        allow :enjoy_games, if: ->{ person.is_child? }
        allow any: true, if_person: :male?
        # forbid :act_fancy
        # forbid %i[mary enjoy_games], if: :priest?
      end

      privilege :human, :noble do
        allow :live_a_bit_more do
          person.male? ? age < 60 : age < 65
        end
        allow any: true
      end

      # privilege :vassal do
      #   allow_on_resource Person, :impose_corvee, require_context: true, if: :is_from_region?
      #   allow_on :villages, :list
      #   allow_on_resource [Region, Village], :impose_levy, require_context: true, if: [
      #       :==,
      #       -> (resource, _) { !resource.expemt_from_levy_by? self },
      #   ]
      #   allow_on_resource [Region, Village], :impose_recruitment, pass_context: true do |resource, context|
      #     context && resource.from_region?(context)
      #   end
      # end
      #
      # privilege :priest do
      #   allow_on Person, :list
      #   allow_on_resource :persons, :forgive_sins, unless_person: :is_devil?
      #   allow_on_resource Village, :perform_mass, require_context: true, if: [
      #       :belongs_to_region?,
      #       -> (resource, _) { !resource.banned_by_pope? }
      #   ]
      # end
      #
      # privilege :bishop do
      #   on_resource Person do
      #     allow :make_a_priest
      #   end
      #   allow_on_resource Region, :perform_mass, require_context: true, if: :==
      # end
      #
      # privilege :pope do
      #   allow_on_resource Person, %i[make_a_bishop]
      #   allow_on_resource Village, :perform_mass
      #   allow_on_resource :regions, :perform_mass, :ban
      # end
      #
      # privilege :emperor do
      #   allow_on_resource Person, resource_actions: {except: %i[create update]}
      #   forbid Village, :perform_mass
      #   forbid :regions, :perform_mass
      #   allow any_action: true
      # end
      #
      # privilege :god do
      #   allow_on_resource Person, any_action: true
      # end

    end
  end

  # module Index
  #
  #   def records
  #     @records ||= {}
  #   end
  #
  #   def [] name
  #     records[name] || (raise "no such record: #{self.class.name} - #{name}")
  #   end
  #
  # end

end

require_relative './middle_ages/person'
require_relative './middle_ages/privilege'
