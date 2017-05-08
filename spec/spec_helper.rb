require_relative '../lib/admission'
require_relative 'rspec_config'

require 'byebug'

def with_bug
  $bug = true
  yield
ensure
  $bug = false
end