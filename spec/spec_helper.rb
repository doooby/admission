require 'rspec_config'

require 'byebug'

def bug
  $bug = true
  yield
ensure
  $bug = false
end

RSpec::Matchers.define :have_inst_vars do |expected|
  match do |object|
    expected.to_a.all? do |var_name, value|
      var = object.instance_variable_get "@#{var_name}"
      var == value
    end
  end
end

require 'simplecov'
SimpleCov.start do
  add_filter %r~^(?!/lib/)~
end

require_relative '../lib/admission'

class String
  def tableize
    "#{self.downcase}s"
  end
end

require_relative '../lib/admission/rails'
