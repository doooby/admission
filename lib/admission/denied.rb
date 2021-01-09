module Admission
  class Denied < ::StandardError

    attr_reader :arbitration

    def initialize arbitration
      @arbitration = arbitration
    end

    def message
      "admission denied to #{arbitration.case_to_s}"
    end

    alias to_s message

  end
end
