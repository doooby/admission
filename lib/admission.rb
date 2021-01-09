module Admission

  NO_SCOPE = 'no-scope'.freeze

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

  def self.resource_type_to_scope type
    "#{type.name.downcase}s"
  end

  def self.nested_scope resource, scope
    unless resource.is_a?(Symbol) || resource.is_a?(String)
      resource = resource_type_to_scope resource
    end
    "#{resource}:#{scope}"
  end

end

require 'admission/version'
require 'admission/privilege'
require 'admission/privileges_order'
require 'admission/rules_builder'
require 'admission/status'
require 'admission/arbitration'
require 'admission/denied'
