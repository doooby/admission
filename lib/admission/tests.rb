module Admission::Test

  class << self
    attr_accessor :all_privileges

    def assertion_failed_message arbitration, privilege
      'Admission denied to %s using %s' % [
          arbitration.case_to_s,
          privilege.to_s
      ]
    end

    def refutation_failed_message arbitration, privilege
      'Admission given to %s using %s' % [
          arbitration.case_to_s,
          privilege.to_s
      ]
    end

    def separate_privileges selector=nil, inheritance: false, list: all_privileges, &block
      selector = block unless selector

      block = case selector
        when String
          if inheritance
            ref_privilege = UserStatus.privileges.get *Admission::Privilege.split_text_key(selector)
            ->(p){ p.eql_or_inherits? ref_privilege }

          else
            ->(p){ p.text_key == selector }

          end
        when Array
          if inheritance
            ref_privileges = selector.map do |s|
              UserStatus.privileges.get *Admission::Privilege.split_text_key(s)
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

end