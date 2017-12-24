module Admission::Rails

  class << self

    attr_accessor :logger
    attr_accessor :log_access

  end

  self.logger = ::Rails.logger

end

require_relative './rails/action_admission'
require_relative './rails/controller_addon'
require_relative './rails/scope_resolver'
require_relative './rails/scope_not_defined'