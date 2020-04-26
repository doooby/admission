module Admission

  # VALID_DECISION = [true, false, :forbidden, nil].freeze
  # ALL_ACTION = :'^'

  class << self

    attr_accessor :debug_request

  end

  def self.define_privileges &block
    builder = PrivilegesOrder::Builder.new &block
    PrivilegesOrder.new builder
  end

  def self.define_rules privileges, &block
    builder = Ruleset::Builder.new privileges, &block
    Ruleset.new builder
  end

  def self.type_to_scope type
    "#{type.name.downcase}s"
  end

  def self.nested_scope resource, scope
    unless resource.is_a?(Symbol) || resource.is_a?(String)
      resource = type_to_scope resource
    end
    "#{resource}:#{scope}"
  end

  def self.resource_to_s resource
    if resource.respond_to? :id
      "#{resource.class.name}[#{resource.id || 'new'}]"
    else
      resource.to_s
    end
  end


  # def self.print_rules rules
  #   unless Hash === rules
  #     raise ArgumentError.new('must be rules')
  #   end
  #
  #   rules.each do |privilege, rule|
  #     if Proc === rule
  #       rule = "#{rule.source_location.join(':')}\n#{rule.source}"
  #     end
  #     puts "#{privilege.inspect}\n\t#{rule}"
  #   end
  # end

end