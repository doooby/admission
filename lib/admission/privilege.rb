class Admission::Privilege

  RESERVED_ID = :'^'
  TOP_LEVEL_KEY = RESERVED_ID
  BASE_LEVEL_NAME = :base

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

  def dup_with_context context
    return self if context.nil? || context.empty?
    with_context = dup
    with_context.instance_variable_set :@context, context
    with_context
  end

  def eql? other
    hash == other.hash
  end

  def text_key
    "#{name}-#{level}"
  end

  def to_s
    "<#{[
        'Privilege',
        "key=#{text_key}",
        (inherited && "inherited=[#{inherited.map(&:text_key).join ','}]")
    ].compact.join ' '}>"
  end
  alias :inspect :to_s

  def self.define_order &block
    Admission::PrivilegesDefiner.define &block
  end

end