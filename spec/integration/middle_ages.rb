module MiddleAges

  class Region < Struct.new(:name)
    def self.name; 'Region'; end
    EXEMPT_FROM_LEVY = [ :nesselsdorf ]
  end

  def self.privileges
    @privileges ||= Admission.define_privileges klass: Privilege do
      privilege :human,    grades: %i[noble]
      privilege :vassal
      # privilege :priest,   grades: %i[bishop pope]
      # privilege :emperor,  inherits: %i[human-noble priest-pope]
      # privilege :god
    end
  end

  def self.rules
    @rules ||= Admission.define_rules privileges do

      # is_from_users_region = -> (resource, region) { resource.from_region? region }

      privilege :human do
        allow :live_a_bit_more do
          person.female? ? person.age < 50 : person.age < 45
        end
        allow :enjoy_games, if: ->{ person.is_child? }
        allow :be_self, if_person: :male?
        allow :mary, unless: :priest?
        allow :be_a_bit_basic
      end

      privilege :human, :noble do
        allow %i[live_a_bit_more] do
          person.male? ? age < 60 : age < 65
        end
        allow :be_self, :act_fancy
        disallow :be_a_bit_basic
      end

      privilege :vassal do
        allow_on_resource Person, :impose_corvee, if: :same_region_as?
        allow_on :persons, :frown_upon
        allow_on_resource [Region, :villages], :impose_levy do |region|
          next false if Region::EXEMPT_FROM_LEVY.include? region.name
          self.region == region
        end
        allow :impose_recruitment, on: [Region, :villages], resource: true, if: :same_region_as?
      end

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

end

require_relative './middle_ages/person'
require_relative './middle_ages/privilege'
