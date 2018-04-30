module Admission

  VALID_DECISION = [true, false, :forbidden, nil].freeze
  ALL_ACTION = :'^'

  class << self

    attr_accessor :debug_arbitration

  end

  def self.define_privileges &block
    index = Admission::PrivilegesOrder::Definer.define &block
    Admission::PrivilegesOrder.new index
  end

end