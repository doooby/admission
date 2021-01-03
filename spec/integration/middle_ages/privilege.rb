module MiddleAges
  class Privilege < Admission::Privilege
    alias person status
  end
end
