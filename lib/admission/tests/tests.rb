module Admission::Tests

  class << self
    attr_accessor :order
    attr_accessor :all_privileges

    def assertion_failed_message arbitration, privilege
      'Admission denied to %s applying %s.' % [
          arbitration.case_to_s,
          privilege.to_s
      ]
    end

    def refutation_failed_message arbitration, privilege
      'Admission given to %s applying %s.' % [
          arbitration.case_to_s,
          privilege.to_s
      ]
    end

    def separate_privileges selector=nil, inheritance: true, list: all_privileges, &block
      selector = block unless selector
      selector = [selector] if selector.is_a? String

      block = case selector
      when Array
        if inheritance
          ref_privileges = selector.map do |s|
            order.get *Admission::Privilege.split_text_key(s)
          end
          ->(p){
            ref_privileges.any?{|ref_p| p.eql_or_inherits? ref_p }
          }

        else
          ->(p){ selector.include? p.text_key }

        end

      when Proc
        selector

      else raise ArgumentError.new('bad selector type')
      end

      list.partition &block
    end

  end

  @all_privileges = []

  class Evaluation

    attr_reader :status, :arbitration

    def initialize status, scope
      @status = status
      @scope = scope
    end

    def request= name
      @arbitration = status.instantiate_arbitration name.to_sym, @scope
    end

    def for_request name
      self.request = name
      self
    end

    def evaluate privilege
      arbitration.prepare_sitting privilege.context
      arbitration.rule_per_privilege(privilege).eql?(true)
    end

    def evaluate_groups to_assert, to_refute
      to_assert = to_assert.map{|p| ContextSpecificPrivilege.new p}
      to_refute = to_refute.map{|p| ContextSpecificPrivilege.new p}
      sorted = (to_assert + to_refute).sort_by{|p| p.privilege.context}
      admissible, denied = sorted.partition{|p| evaluate p.privilege}

      [
          (denied - to_refute),
          (admissible - to_assert)
      ]
    end

    def messages_for_groups should, should_not
      [
          should.map{|p| Admission::Tests.assertion_failed_message arbitration, p.privilege},
          should_not.map{|p| Admission::Tests.refutation_failed_message arbitration, p.privilege}
      ].flatten
    end

  end

  class ContextSpecificPrivilege

    attr_reader :privilege

    def initialize privilege
      @privilege = privilege
      @hash = [privilege.name, privilege.level, privilege.context].hash
    end

    def eql? other
      hash == other.hash
    end

  end

  class RuleCheckContext

    attr_reader :action

    def initialize
      @evaluations = []
      action = yield self
      self.set_rule_check_action = action if !self.action && Proc === action
    end

    def data
      @data ||= {}
    end

    def set value
      case value
      when Proc then @data_builder = value
      when Hash then @data = value
      else raise('context must be Hash or Proc')
      end
    end

    def prepare *args, &block
      raise 'context is static (i.e. context was not set to a Proc)' unless @data_builder
      @data = @data_builder.call *args, &block
    end

    def set_rule_check_action= action
      @action = action
    end

    def [] value
      data[value]
    end

    def []= name, value
      data[name] = value
    end

    def add_evaluation *args
      evaluation = Evaluation.new *args
      @evaluations.push evaluation
      evaluation
    end

    def evaluate request
      raise 'no evaluation preset' if @evaluations.empty?
      @evaluations.each do |evaluation|
        evaluation.request = request
        yield evaluation
      end
    end

  end

end
