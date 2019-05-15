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

  def self.print_rules rules
    unless Hash === rules
      raise ArgumentError.new('must be rules')
    end

    rules.each do |privilege, rule|
      if Proc === rule
        rule = "#{rule.source_location.join(':')}\n#{rule.source}"
      end
      puts "#{privilege.inspect}\n\t#{rule}"
    end
  end

end