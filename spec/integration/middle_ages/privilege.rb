module MiddleAges
  class Privilege < Admission::Privilege
    alias person status
    attr_accessor :person
  end
end
