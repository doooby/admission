class Admission::Status

  attr_reader :person, :privileges

  def initialize person
    @person = person
    @privileges = []
    yield self if block_given?
  end

  def add_privilege name, level, *context_args
    privilege = Admission.get_privilege name, level
    @privileges << privilege.dup_with_context(context_args) if privilege
  end

end