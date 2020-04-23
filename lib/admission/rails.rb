module Admission::Rails; end

Admission::ResourceArbitration.class_exec do

  # use active_support's inflection to get the scope of resource type
  def self.type_to_scope type
    type.name.tableize.to_sym
  end

end

require_relative './rails/action_admission'
require_relative './rails/controller_addon'
require_relative './rails/scope_resolver'
