module Admission
  class Denied < ::StandardError

    attr_reader :status, :arbitration

    def initialize status, *request_args
      @status = status
      @arbitration = status.instantiate_arbitration *request_args
    end

    def message
      "admission denied to #{arbitration.case_to_s}"
    end

    alias to_s message

  end
end
