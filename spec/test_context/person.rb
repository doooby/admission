
class Person

  attr_reader :name, :sex, :countries
  attr_reader :privileges, :rules

  FEMALE            = 0
  MALE              = 1
  APACHE_HELICOPTER = 2

  def initialize name, sex, countries
    @name = name
    @sex = sex
    @countries = countries
  end

  def not_woman?
    @sex != FEMALE
  end

  def person
    self
  end

  def allow_possession_change? _, country
    countries.include? country
  end

end