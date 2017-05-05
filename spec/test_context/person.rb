
class Person

  attr_reader :name, :sex
  attr_reader :privileges, :ability_rules

  FEMALE            = 0
  MALE              = 1
  APACHE_HELICOPTER = 2

  def initialize name, sex
    @name
    @sex = sex
  end

  def countries
     []
  end

  # privileges per country

  def not_woman?
    @sex != FEMALE
  end

  def person
    self
  end

  # def self.reduce_privileges **per_country
  # end

end