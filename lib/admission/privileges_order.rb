module Admission
  class PrivilegesOrder

    attr_reader :privilege_klass, :names

    def initialize builder, privilege_klass
      @grades_index = builder.grades_index.freeze
      @grades_index.values.each(&:freeze)

      @inheritance_index = builder.inheritance_index.freeze
      @inheritance_index.values.each(&:freeze)

      @names = @inheritance_index.keys.freeze

      @privilege_klass = privilege_klass
      freeze
    end

    def get status, name, *args
      name = name.to_s.freeze
      validate_name! name
      @privilege_klass.new status, name, *args
    end

    def top_down_grades_for name
      @grades_index[name]
    end

    def inheritance_list_for name
      @inheritance_index[name]
    end

    private

    def validate_name! name
      unless @names.include? name
        raise Admission::Privilege::NotDefinedError.new(self, name)
      end
    end

    class Builder

      attr_reader :grades_index, :inheritance_index

      def initialize &block
        @grades_index = {}
        @inheritance_index = {}
        instance_exec &block
      end

      def privilege name, grades: [], inherits: []
        name = name.to_s
        grades.map!{|grade| grade.to_s.freeze }

        # build grades full names
        grades.unshift nil # aka base grade
        grades.map!{|grade| Admission::Privilege.produce_combined_name name, grade}

        # fill in grades index
        top_down_grades = grades.reverse
        top_down_grades.each_with_index do |privilege, index|
          grades_index[privilege] = top_down_grades[index .. -1]
        end

        # fetch inherited privileges
        # must be already defined
        inherits.map! do |privilege|
          privilege = privilege.to_s
          unless grades_index.keys.include? privilege
            raise "privilege #{name} cannot inherit undefined privilege #{privilege}"
          end
          privilege
        end

        # define privileges with grade inheritance
        grades.each_with_index do |privilege, index|
          inheritance = inherits.dup
          inheritance.unshift grades[index + 1] unless index == 0
          inheritance_index[privilege] = inheritance
        end
      end

    end

  end
end
