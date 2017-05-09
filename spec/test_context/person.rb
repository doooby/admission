
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