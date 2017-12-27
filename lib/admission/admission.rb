module Admission

  VALID_DECISION = [true, false, :forbidden, nil].freeze
  ALL_ACTION = :'^'

  class << self

    attr_accessor :debug_arbitration

  end

end