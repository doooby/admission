module Admission::Tests

  class << self

    attr_accessor :order
    
    attr_writer :all_privileges
    def all_privileges
      @all_privileges ||= PrivilegesHelper.new(order.to_list)
    end

    def fail_message case_text, privileges_to_assert, privileges_to_refute
      normalize_group = -> (group) {
        if group && !group.empty?
          group.map(&:to_s).join(', ')
        end
      }

      to_assert = normalize_group.(privileges_to_assert)
      to_refute = normalize_group.(privileges_to_refute)

      [
        "Admission: #{case_text}",
        ("\tfailed to assert for: #{to_assert}" if to_assert),
        ("\tfailed to refute for: #{to_refute}" if to_refute),
      ].join "\n"
    end

    def process_rule status, privilege, request, scope, &block
      arbitration = status.instantiate_arbitration request, scope
  
      fn = -> (p) {
        arbitration.prepare_sitting p.context
        result = arbitration.rule_per_privilege(p).eql?(true)
        block.call result, p, arbitration
      }
  
      [privilege].flatten.compact.to_a.each(&fn)
    end

  end

  class RuleHelper

    attr_reader :request, :to_assert, :to_refute
    attr_accessor :status, :scope, :scope_label
  
    def initialize context, request
      @context = context
      @request = request
    end
  
    def to_assert= *privileges
      privileges = privileges.flatten.compact
      @to_assert = privileges unless privileges.empty?
    end
  
    def to_refute= *privileges
      privileges = privileges.flatten.compact
      @to_refute = privileges unless privileges.empty?
    end
  
    # cached the `@failed` as: `{to_assert: [], to_refute: []}`
    def result
      @failed = {
        to_assert: nil,
        to_refute: nil
      }

      if to_assert
        failed = to_assert.reject &(method :rule_per_privilege)
        @failed[:to_assert] = failed unless failed.empty?
      end

      if to_refute
        failed = to_refute.select &(method :rule_per_privilege)
        @failed[:to_assert] = failed unless failed.empty?
      end

      @failed.values.all? &:nil?
    end
    alias :call :result
  
    def fail_msg
      Admission::Tests.fail_message(
        scope_msg, 
        @failed[:to_assert], 
        @failed[:to_refute]
      )
    end
  
    private
  
    def arbitration
      @arbitration ||= status.instantiate_arbitration(request, scope)
    end

    def rule_per_privilege privilege
      arbitration.prepare_sitting privilege.context
      arbitration.rule_per_privilege(privilege).eql?(true)
    end
  
    def scope_msg
      if scope_label
        "#{@request} -> #{arbitration.scope} (#{scope_label})"
      else
        arbitration.case_to_s
      end
    end
  
  end

  class PrivilegesHelper

    attr_reader :to_a
    alias :to_ary :to_a

    def initialize list
      @to_a = list.to_a
    end

    def select *args, **kwargs, &block
      selector = build_selector *args, **kwargs, &block
      PrivilegesHelper.new to_a.select(&selector)
    end

    def reject *args, **kwargs, &block
      selector = build_selector *args, **kwargs, &block
      PrivilegesHelper.new to_a.reject(&selector)
    end

    def partition *args, **kwargs, &block
      selector = build_selector *args, **kwargs, &block
      to_a.partition(&selector).map do |list|
        PrivilegesHelper.new list
      end
    end

    private

    def build_selector selector=nil, inheritance: true, &block
      selector = block unless selector
      selector = [selector] if selector.is_a? String

      case selector
        when Array
          if inheritance
            ref_privileges = selector.map do |s|
              Admission::Tests.order.get *Admission::Privilege.split_text_key(s)
            end
            ->(p){
              ref_privileges.any?{|ref_p| p.eql_or_inherits? ref_p }
            }

          else
            ->(p){ selector.include? p.text_key }

          end

        when Proc
          selector

        else 
          raise ArgumentError, 'bad selector type'

      end
    end
  end

  if defined?(Admission::Rails)
    class ActionHelper

      attr_reader :context, :controller
      attr_accessor :action, :params

      def initialize context, controller
        @context = context
        @controller = controller.new
        @params = {}
        helper = self

        mock(:action_name){ helper.action.to_s }
        mock(:params){ helper.params }
        
        mock :request_admission! do |_, scope|
          helper.instance_variable_set '@result_scope', scope
        end
      end

      def self.mock controller, context=nil, &imediate_call
        mock = -> (context_override=nil, &block) {
          helper = Admission::Tests::ActionHelper.new(
            (context_override || context),
            controller
          )
          block.call helper
        }
        mock.(&imediate_call) if imediate_call
        mock
      end

      def result
        validate_action!
        
        @result_scope = nil
        controller.send :assure_admission
        @result_scope
      end

      def call action=nil, params=nil
        self.action = action if action
        self.params = params if params
        result
      end

      private

      def mock method, &block
        controller.define_singleton_method method, &block
      end

      def validate_action!
        raise ArgumentError, "action must be set" if action.nil?
        unless controller.respond_to? action
          raise ArgumentError, "no such action #{controller.class.name}##{action}" 
        end
      end

    end
  end

end
