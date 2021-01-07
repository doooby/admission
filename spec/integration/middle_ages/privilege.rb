module MiddleAges
  class Privilege < Admission::Privilege
    alias person status
    attr_accessor :person

    attr_reader :region

    def initialize status, name, region
      super status, name
      @region = region
    end

    def same_region_as? resource
      return false if region.nil?

      if resource.respond_to? :belongs_to_region?
        region_name = region.is_a?(Region) ? region.name : region
        resource.belongs_to_region? region_name

      elsif resource.is_a? Region
        region.name == resource.name

      end
    end

    def priest?
      name == :priest
    end
  end
end
