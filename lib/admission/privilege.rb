class Admission::Privilege

  RESERVED_ID = :'^'.freeze
  TOP_LEVEL_KEY = RESERVED_ID
  BASE_LEVEL_NAME = :base
  SEPARATOR = '-'.freeze

  attr_reader :name, :level, :hash
  attr_reader :inherited, :context

  def initialize name, level=nil
    name = name.to_sym
    @name = name
    level = level ? level.to_sym : BASE_LEVEL_NAME
    @level = level
    @hash = [name, level].hash
  end

  def inherits_from *privileges
    @inherited = privileges
  end

  def dup_with_context context=nil
    return self if context.nil?
    with_context = dup
    with_context.instance_variable_set :@context, context
    with_context
  end

  def eql? other
    hash == other.hash
  end

  def eql_or_inherits? sought
    return true if eql? sought
    return false unless inherited
    inherited.any?{|pi| pi.eql_or_inherits? sought}
  end

  def text_key
    @text_key ||= level == BASE_LEVEL_NAME ? name.to_s : "#{name}#{SEPARATOR}#{level}"
  end

  def self.split_text_key value
    return value.split(SEPARATOR)
  end

  def inspect
    "#<#{[
        'Privilege',
        "key=#{text_key}",
        (inherited && "inherited=[#{inherited.map(&:text_key).join ','}]")
    ].compact.join ' '}>"
  end

  def to_s
    [
        "privilege #{text_key}",
        (context && ", context #{context}")
    ].join ''
  end

  def self.get_from_order order, name, level=nil
    levels = order[name.to_sym] || return
    if level && !level.empty?
      levels[level.to_sym]
    else
      levels[Admission::Privilege::BASE_LEVEL_NAME]
    end
  end

  # def self.order_to_list order
  #   order.values.map(&:values).flatten.uniq
  # end
  #
  # def self.get_inheritors_for list, order
  #   list = [list] unless list.is_a? Array
  #
  #   privileges_list.select do |p|
  #     list.any?{|ref_p| p.eql_or_inherits? ref_p }
  #   end
  # end

  def self.order_to_array index
    index.values.map(&:values).flatten.uniq
  end

end