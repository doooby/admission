require_relative '../lib/admission'
require_relative 'rspec_config'

require 'byebug'

def with_bug
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