
class Person

  attr_reader :sex, :privileges

  FEMALE            = 0
  MALE              = 1
  APACHE_HELICOPTER = 2

  def initialize sex, privileges={}
    @sex = sex
    @privileges = @privileges
  end

  def countries
     []
  end

  # privileges per country

  def not_women?
    @sex != FEMALE
  end

end