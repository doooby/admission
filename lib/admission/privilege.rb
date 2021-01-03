module Admission
  class Privilege

    RESERVED_ID = :'^'
    TOP_GRADE_KEY = RESERVED_ID
    BASE_GRADE = :base
    NAME_SEPARATOR = '-'.freeze

    attr_reader :status, :name

    def initialize status, name
      @status = status
      @name = name.to_sym
    end

    def eql? other
      name == other.name
    end

    # def eql_or_inherits? sought
    #   return true if eql? sought
    #   return false unless inherited
    #   inherited.any?{|pi| pi.eql_or_inherits? sought}
    # end

    def self.produce_combined_name name, grade
      if grade.nil?
        name.to_sym
      else
        :"#{name}#{NAME_SEPARATOR}#{grade}"
      end
    end

    # def self.separate_name value
    #   value.split NAME_SEPARATOR
    # end

    # def inspect
    #   details = [
    #       'Privilege',
    #       text_key,
    #       (inherited && "inherited=[#{inherited.map(&:text_key).join ','}]"),
    #       (context && "context=#{context}")
    #   ].compact
    #   "#<#{details.join ' '}>"
    # end

    # def to_s
    #   if context
    #     "#{text_key}[#{context}]"
    #   else
    #     text_key
    #   end
    # end

    class NotDefinedError < ::StandardError

      attr_reader :order, :name

      def initialize order, name
        @order = order
        @name = name
      end

      def message
        "privilege #{name} is not defined in the #{order.class}"
      end

      alias to_s message

    end

  end
end
