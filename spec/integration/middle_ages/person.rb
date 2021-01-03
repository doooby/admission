module MiddleAges
  class Person
    include Admission::Status

    attr_accessor :name, :age, :sex, :residence

    FEMALE            = 0
    MALE              = 1
    APACHE_HELICOPTER = 2

    def initialize name, age, sex, residence
      self.name = name
      self.age = age
      self.sex = sex
      @residence = residence
    end

    def sex= sex
      @sex = case sex
        when :male then MALE
        when :female then FEMALE
        else APACHE_HELICOPTER
      end
    end

    def create_admission_arbitration request, scope
      Admission::Arbitration2.new MiddleAges.privileges, MiddleAges.rules, request, scope
    end

    def is_child?
      age < 10
    end

    def male?
      sex == MALE
    end

    def female?
      sex == FEMALE
    end

  end
end
