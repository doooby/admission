class String
  def tableize
    "#{self.downcase}s"
  end
end

require_relative 'country'
require_relative 'person'

require_relative 'privileges_and_rules'
require_relative 'persons_fixtures'