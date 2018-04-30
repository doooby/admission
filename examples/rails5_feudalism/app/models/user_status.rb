Admission::Privilege.class_exec do
  alias country context
end

class UserStatus < Admission::Status

  def self.for_user user
    new user, parse_privileges(user.privileges), rules, Admission::ResourceArbitration
  end

  def self.privilege_for_country name, level, country
    privileges.get(name, level).dup_with_context country
  end

  def self.parse_privileges privileges
    list = []
    return list unless privileges && privileges.is_a?(Hash)
    privileges = privileges.stringify_keys

    (privileges.keys & Person::COUNTRIES).each do |country|
      records = privileges[country.to_s].presence || next
      records.uniq.each do |record|
        name, level = Admission::Privilege.split_text_key record
        list << privilege_for_country(name, level, country)
      end
    end

    list.compact
  end

  def self.dump_privileges list
    return if list.blank?

    hash = list.inject Hash.new do |hash, privilege|
      (hash[privilege.country] ||= []) << privilege.text_key
      hash
    end

    hash['_all'] = list.map(&:text_key).uniq

    hash
  end

  def self.privilege_key_to_text text_key
    case text_key
      when 42 then 'the very answer'
      else text_key
    end
  end

  def self.privileges
    @privileges ||= Admission.define_privileges do
      privilege :human, levels: %i[adult adult_white_male]
      privilege :lord, inherits: %i[human]
      privilege :duke, inherits: %i[human]
    end
  end

  def self.privileges_list
    @privileges_list ||= Admission::Privilege.order_to_array(privileges)
  end

  def self.rules
    @rules ||= Admission::ResourceArbitration.define_rules privileges do

      get_object_person = -> (object) {
        if object.is_a? Person
          object
        elsif object.respond_to? :person
          object.person
        end
      }

      same_person = -> (object, _) {
        object_person = get_object_person[object]
        return :forbidden unless object_person
        object_person == self.person
      }

      same_country = -> (object, country) {
        object_person = get_object_person[object]
        return :forbidden unless object_person
        object_person.country == country
      }

      ###############

      privilege :human do

        # can have possessions, can try to make new
        allow nested_scope(Person, :possessions), %i[index new]

        # is aware of own traits
        allow type_to_scope(Trait), :index

      end

      privilege :human, :adult do

        # can do anything with his own possessions
        allow nested_scope(Person, :possessions), %i[create]
        allow_resource [Person, :possessions], %i[edit update destroy], &same_person

        # can work only on self
        allow_resource Trait, %i[edit update destroy], &same_person

      end

      privilege :human, :adult_white_male do

        # can desire to work on self to achieve new traits
        allow type_to_scope(Trait), %i[new create]

      end

      privilege :lord do

        # is entitled to know what possessions exists in his country, and impound them
        allow_resource [Person, :possessions], :impound, &same_country

        # is entitled to command his people
        allow type_to_scope(Trait), %i[index new create]
        allow_resource Trait, %i[edit update destroy], &same_country

      end

      privilege :duke do

        # as a sovereign can impose ownership changes
        allow_resource [Person, :possessions], %i[hand_over_to destroy], &same_country

        # is entitled to command his people - also?
        allow_resource :traits, %i[edit update destroy], &same_country

      end

    end
  end

end