module Admission

  asterisk_char = '*'.freeze
  NO_SCOPE = asterisk_char
  ANY_ACTION = asterisk_char

  class << self

    attr_accessor :debug_arbitration

    def define_privileges klass: Privilege, &block
      builder = PrivilegesOrder::Builder.new &block
      PrivilegesOrder.new builder, klass
    end

    def define_rules privileges, &block
      builder = Admission::RulesBuilder.new privileges, &block
      builder.produce_index
    end

  end

  # def self.type_to_scope type
  #   "#{type.name.downcase}s"
  # end
  #
  # def self.nested_scope resource, scope
  #   unless resource.is_a?(Symbol) || resource.is_a?(String)
  #     resource = type_to_scope resource
  #   end
  #   "#{resource}:#{scope}"
  # end
  #
  # def self.resource_to_s resource
  #   if resource.respond_to? :id
  #     "#{resource.class.name}[#{resource.id || 'new'}]"
  #   else
  #     resource.to_s
  #   end
  # end

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

require 'admission/version'

require 'admission/privilege'
require 'admission/privileges_order'
require 'admission/rules_builder'
require 'admission/status'
# require 'admission/arbitration'
# require 'admission/resource_arbitration'
require 'admission/arbitration2'

# require 'admission/attributes'

require 'admission/denied'
