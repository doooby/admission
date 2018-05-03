module Admission::Tests

  class << self
    attr_accessor :order
    attr_accessor :all_privileges

    def assertion_failed_message arbitration, privilege
      'Admission denied to %s applying %s' % [
          arbitration.case_to_s,
          privilege.to_s
      ]
    end

    def refutation_failed_message arbitration, privilege
      'Admission given to %s applying %s' % [
          arbitration.case_to_s,
          privilege.to_s
      ]
    end

    def separate_privileges selector=nil, inheritance: false, list: all_privileges, &block
      selector = block unless selector

      block = case selector
      when String
        if inheritance
          ref_privilege = order.get *Admission::Privilege.split_text_key(selector)
          ->(p){ p.eql_or_inherits? ref_privilege }

        else
          ->(p){ p.text_key == selector }

        end
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

    def action= name
      @arbitration = status.instantiate_arbitration name.to_sym, @scope
    end

    def for_action name
      self.action = name
      self
    end

    def evaluate privilege
      arbitration.prepare_sitting privilege.context
      arbitration.rule_per_privilege(privilege).eql?(true)
    end

    def evaluate_groups to_assert, to_refute
      to_assert = to_assert.map{|p| ContextSpecificPrivilege.new p}
      to_refute = to_refute.map{|p| ContextSpecificPrivilege.new p}
      admissible, denied = (to_assert + to_refute).
          sort_by{|p| p.privilege.context}.
          partition{|p| evaluate p.privilege}

      groups = [
          [ (denied - to_refute), :assertion_failed_message ],
          [ (admissible - to_assert), :refutation_failed_message ],
      ]
      groups.map! do |group, message_getter|
        group.map{|p| Admission::Tests.send message_getter, arbitration, p.privilege}
      end
      groups.flatten
    end

    def evaluate_rule action, to_assert, to_refute
      self.action = action
      evaluate_groups to_assert, to_refute
    end
    alias call evaluate_rule

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

    def initialize
      @evaluations = []
      yield self
    end

    def get
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

    def [] value
      get[value]
    end

    def []= name, value
      get[name] = value
    end

    def add_evaluation *args
      evaluation = Evaluation.new *args
      @evaluations.push evaluation
      evaluation
    end

    def evaluate action
      raise 'no evaluation preset' if @evaluations.empty?
      @evaluations.each do |evaluation|
        evaluation.action = action
        yield evaluation
      end
    end

  end

end
