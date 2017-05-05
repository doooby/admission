class Admission::Status

  attr_reader :person, :privileges, :ability_rules

  def initialize person, privileges, ability_rules
    @person = person
    @privileges = privileges
    @ability_rules = ability_rules
  end

end