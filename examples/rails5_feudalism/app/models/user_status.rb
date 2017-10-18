Admission::Privilege.class_exec do
  alias country context
end

class UserStatus < Admission::Status

  COUNTRIES = %w[Bohemia Moravia Silesia].freeze

  def self.for_user user
    new user, parse_privileges(user.privileges), rules, Admission::ResourceArbitration
  end

  def self.privilege_for_country name, level, country
    Admission::Privilege.get_from_order(privileges, name, level).dup_with_context country
  end

  def self.parse_privileges privileges
    list = []
    return list unless privileges && privileges.is_a?(Hash)
    privileges = privileges.stringify_keys

    (privileges.keys & COUNTRIES).each do |country|
      records = privileges[country.to_s].presence || next
      records.uniq.each do |record|
        name, level = record.split '-'
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

  def self.privileges_list
    @privileges_list ||= privileges.values.map(&:values).flatten.uniq
  end

  def self.privilege_key_to_text text_key
    case text_key
      when 42 then 'the very answer'
      else text_key
    end
  end

  def self.privileges
    @privileges ||= Admission::Privilege.define_order do
      privilege :peasant
      privilege :lord
      privilege :duke
    end
  end

  def self.rules
    @rules ||= Admission::ResourceArbitration.define_rules privileges do

      privilege :lord do
        allow :ducks, :to_quack
      end

    end
  end

end