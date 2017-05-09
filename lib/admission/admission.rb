module Admission

  VALID_DECISION = [true, false, :forbidden, nil]
  ALL_ACTION = :all

  def self.type_to_scope type
    :persons
  end


end