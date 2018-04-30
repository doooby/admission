class Admission::PrivilegesOrder

  attr_reader :index

  def initialize index
    @index = index
  end

  def [] name
    index[name]
  end

  class Definer

    attr_reader :definitions

    def initialize
      @definitions = {}
    end

    def privilege name, levels: [], inherits: nil
      name = name.to_sym
      if ([name] + levels).any?{|id| id == Admission::Privilege::RESERVED_ID }
        raise "reserved name `#{Admission::Privilege::RESERVED_ID}` !"
      end

      levels.unshift Admission::Privilege::BASE_LEVEL_NAME
      levels.map!{|level| Admission::Privilege.new name, level}

      inherits = nil if inherits && inherits.empty?
      if inherits
        inherits = *inherits
        inherits = inherits.map(&:to_sym).uniq
      end

      @definitions[name] = {levels: levels, inherits: inherits}
    end

    def self.define &block
      definer = new
      definer.instance_exec &block

      definer.send :setup_inheritance
      definer.send :build_index
    end

    private

    def setup_inheritance
      # set inheritance for all privileges
      definitions.values.each do |levels:, inherits:|
        levels.each_with_index do |privilege, index|
          if index > 0 # higher level of privilege, inherits one step lower level
            privilege.inherits_from levels[index - 1]

          elsif inherits # lowest level, inherits top level of other privileges
            inherits = inherits.map{|name| definitions[name][:levels].last if definitions.has_key? name}
            privilege.inherits_from *inherits

          end
        end
      end
    end

    def build_index
      definitions.each_pair.reduce({}) do |h, pair|
        name = pair[0]
        levels = pair[1][:levels]

        levels_hash = levels.reduce({Admission::Privilege::TOP_LEVEL_KEY => levels.last}) do |lh, privilege|
          lh[privilege.level] = privilege
          lh
        end.freeze

        h[name] = levels_hash
        h
      end.freeze
    end

  end


end