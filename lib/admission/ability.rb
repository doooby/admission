# class Admission::Ability
#
#   attr_reader :status
#
#   def initialize status, arbiter=Admission::RequestArbitration
#     @status = status
#     @no_privileges = @status.privileges.nil? || @status.privileges.empty?
#     @arbiter = arbiter
#   end
#
#   # def can? *agrs
#   #   return false if @no_privileges
#   #   # subject, object = subject_and_object subject
#   #   process @arbiter.new(status)
#   #   process Arbitration.new(status.user, action), subject, object
#   # end
#
#   def cannot? *args
#     !can?(*args)
#   end
#
#   class << self
#
#     # attr_reader :rules_index
#
#     # def define_for_privileges privileges, &block
#     # end
#
#     # def set_up_rules &block
#     #   @rules_index = []
#     #   self.instance_exec &block
#     #   remove_instance_variable :@privilege
#     #
#     #   @rules_index = @rules_index.reduce Hash.new do |index, allowance|
#     #     privilege = allowance[:privilege]
#     #
#     #     actions = allowance[:actions]
#     #     *actions = actions unless Array === actions
#     #     actions = %i[all] if actions.include? :all
#     #
#     #     subject_index = (index[allowance[:subject]] ||= {})
#     #     resource_index = (index[allowance[:resource_type]] ||= {} if allowance[:resource_type])
#     #
#     #     actions.each do |action|
#     #       subject_arbiter = allowance[:arbiter]
#     #
#     #       if resource_index
#     #         action_index = (resource_index[action] ||= {})
#     #         action_index[privilege] = allowance[:arbiter]
#     #
#     #         subject_arbiter = true
#     #       end
#     #
#     #       action_index = (subject_index[action] ||= {})
#     #       action_index[privilege] = subject_arbiter
#     #     end
#     #
#     #     index
#     #   end
#     # end
#
#     # def privilege name, level=nil, &block
#     #   @rules_index || raise('must be called within `set_rules` block')
#     #   @privilege = Admission.get_privilege(name, level) || raise("no such privilege: #{name}-#{level}")
#     #   self.instance_exec &block
#     #   @privilege = nil
#     # end
#     #
#     # def allow subject, actions=:all
#     #   raise 'must be called within `privilege` block' unless @privilege
#     #   @rules_index << {
#     #       privilege: @privilege,
#     #       subject: subject,
#     #       actions: actions,
#     #       arbiter: true
#     #   }
#     # end
#     #
#     # def forbid subject, actions=:all
#     #   raise 'must be called within `privilege` block' unless @privilege
#     #   @rules_index << {
#     #       privilege: @privilege,
#     #       subject: subject,
#     #       actions: actions,
#     #       arbiter: :forbid
#     #   }
#     # end
#     #
#     # def allow_resource type, actions=:all, lambda=nil, &block
#     #   raise 'must be called within `privilege` block' unless @privilege
#     #   @rules_index << {
#     #       privilege: @privilege,
#     #       subject: resource_type_to_subject(type),
#     #       resource_type: type,
#     #       actions: actions,
#     #       arbiter: lambda || block || true
#     #   }
#     # end
#
#     private
#
#     # def resource_type_to_subject type
#     #   raise "bad resource type, must respond to `#name` (should be class)" unless type.respond_to? :name
#     #   name = type.name.downcase
#     #   if name.respond_to? :pluralize
#     #     name.pluralize
#     #   else
#     #     raise 'Not implemented: unable to make subject id from resource without active_support'
#     #   end
#     #
#     # end
#
#   end
#
#   private
#
#   # def subject_and_object object
#   #   Symbol === object ? object : [objec.class, object]
#   # end
#
#   # def process arbitration, subject, object
#   #   all_index = self.class.rules_index[:all]
#   #   subject_index = self.class.rules_index[subject]
#   #   type_index = (self.class.rules_index[object] if object)
#   #   arbitration.introduce_indices all_index, subject_index, type_index
#   #
#   #   status.privileges.any? do |privilege|
#   #     arbitration.prepare_sitting object, *privilege.context
#   #     TrueClass === arbitration.rule(privilege)
#   #   end
#   # end
#
#   def process arbitration
#     status.privileges.any? do |privilege|
#       arbitration.prepare_sitting object, *privilege.context
#       arbitration.rule_per_privilege(privilege).eql? true
#     end
#   end
#
# end