# module Admission::Rails
#
#   class ActionsAdmission
#
#     attr_reader :resource_actions, :resource_loader
#
#     def initialize controller_class
#       @controller_class = controller_class
#     end
#
#     def authorize prepend:false, **options
#       callback_name = prepend ? :prepend_before_action : :before_action
#       options = options.slice(:only, :except, :if, :unless)
#       admission = self
#
#       @controller_class.send callback_name, options  do |controller|
#         ActionAbility.new(controller, admission).authorize!
#       end
#     end
#
#     def resource_actions *actions, loader:nil
#       @resource_actions = actions.flatten
#       @resource_loader = loader || :"find_#{@controller_class.controller_name.singularize}"
#     end
#
#     def is_resource_action? action
#       @resource_actions.present? && @resource_actions.include?(action)
#     end
#
#   end
#
#   class ActionAbility
#     attr_reader :controller
#
#     def initialize controller, admission
#       @controller = controller
#       @admission = admission
#     end
#
#     def authorize!
#       user.ability.can?(action_name, object) || (raise AccessDenied.new(self))
#     end
#
#     def user
#       @controller.current_user
#     end
#
#     def object
#       @object ||= if @admission.is_resource_action?(action_name)
#         @controller.send @admission.resource_loader
#       else
#         @controller.class.controller_name
#       end
#     end
#
#     def action_name
#       @action_name ||= @controller.params[:action].to_sym
#     end
#
#     def object_to_s
#       case object
#         when String then ":#{object}"
#         when ActiveRecord::Base
#           "<#{object.class.name}>"
#         else
#           object.to_s
#       end
#     end
#
#   end
#
#   class AccessDenied < ::StandardError
#     attr_reader :action_ability
#
#     def initialize ability
#       @action_ability = ability
#       @message = "Nemáte oprávnění pro tuto akci. (#{ability.action_name} - #{ability.object_to_s})"
#     end
#
#     def to_s
#       @message
#     end
#   end
#
# end
#
#
# ActionController::Base.instance_exec do
#   def actions_admission &block
#     @actions_admission ||= Admission::Rails::ActionsAdmission.new(self)
#     @actions_admission.instance_exec &block if block
#     @actions_admission
#   end
# end