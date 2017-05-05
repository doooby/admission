module Admission

  # def self.define_privileges &block
  #   @privileges = PrivilegesDefiner.define &block
  # end

  # def self.get_privilege index, name, level=nil
  #   @privileges ||= auto_load_privileges_definitions
  #   levels = @privileges[name.to_sym] || return
  #   level && !level.empty? ? levels[level.to_sym] : levels[Privilege::BASE_LEVEL_NAME]
  # end

end