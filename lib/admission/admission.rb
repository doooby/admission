module Admission

  VALID_DECISION = [true, false, :forbidden, nil]
  ALL_ACTION = :all

  def self.type_to_scope_resolution proc=nil, &block
    @type_to_scope = proc || block
  end

  def self.type_to_scope type
    scope = @type_to_scope && @type_to_scope.call(type)
    scope || :"#{type.name.downcase}s"
  end

end