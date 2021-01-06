module MiddleAges
  class Privilege < Admission::Privilege
    alias person status
    attr_accessor :person

    def priest?
      name == :priest
    end
  end
end
