class Admission::ResourceArbitration < Admission::Arbitration
#
#   def initialize status, request
#     @person = status.person
#     @rules_index = status.rules
#     @request = request.to_sym
#   end
#
#   def decide privilege
#     decision = make_decision @rules_index[@request], privilege
#     return decision if decision.eql?(:forbidden) || decision.eql?(true)
#
#     decision2 = decide_per_inheritance privilege
#     return false if decision2.eql?(:forbidden) && decision.eql?(false)
#     return decision2 if decision2.eql?(:forbidden) || decision2.eql?(true)
#
#     make_decision @rules_index[:all], privilege
#   end
#
# end


# def rule privilege
#   decision = @decisions[privilege]
#   return decision unless decision.nil?
#
#   decision = decide_on_subject privilege
#   decision = decide_on_type privilege if TrueClass === decision && @decide_for_type
#   decision = decide_for_inherited privilege.inherited unless decision
#   decision = false if decision.nil?
#
#   @decisions[privilege] = decision
# end

# def decide_on_subject privilege
#   decision = nil
#
#   # special any subject index (subject = :all)
#   decision = @all_all_index[privilege] if @all_all_index
#   return decision if decision
#   decision = @actions_all_index[privilege] if @actions_all_index
#   return decision if decision
#
#   # particular subject index
#   decision = @all_subject_index[privilege] if @all_subject_index
#   return decision if decision
#   @action_subject_index[privilege] if @action_subject_index
# end

# def decide_on_type privilege
#   decision = nil
#
#   decision = @all_type_index[privilege] if @all_type_index
#   decision = decision.call *@context if Proc === decision
#   return decision if decision
#
#   decision = @action_type_index[privilege] if @action_type_index
#   decision = decision.call *@context if Proc === decision
#   decision
# end

# def introduce_indices all_index, subject_index, type_index
#   all_index = self.class.rules_index[:all]
#   subject_index = self.class.rules_index[subject]
#   type_index = (self.class.rules_index[object] if object)
#   arbitration.introduce_indices all_index, subject_index, type_index
#
#   if all_index
#     @all_all_index = all_index[:all]
#     @actions_all_index = all_index[action]
#   end
#
#   @all_subject_index = subject_index[:all]
#   @action_subject_index = subject_index[action]
#
#   if type_index
#     @decide_for_type = true
#     @all_type_index = subject_index[:all]
#     @action_type_index = subject_index[action]
#   end

  def self.define_rules privilege_order, &block
    # builder = Admission::ResourceArbitration::RulesBuilder.new privilege_order
    # builder.instance_exec &block
    # builder.create_index
  end

end