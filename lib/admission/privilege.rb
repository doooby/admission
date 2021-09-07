module Admission
  class Privilege

    BASE_GRADE = :base
    NAME_SEPARATOR = '-'.freeze

    attr_reader :status, :name

    def initialize status, name
      @status = status
      @name = name
    end

    def eql? other
      name == other.name
    end

    def self.produce_combined_name name, grade
      if grade.nil?
        name
      else
        "#{name}#{NAME_SEPARATOR}#{grade}".freeze
      end
    end

    def inspect
      attrs_list = [
          "name=#{name}",
      ]
      "<#{self.class} #{attrs_list.join ' '}>"
    end

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
