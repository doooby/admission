# require_relative './ddle_ages_spec'
#
# RSpec.describe 'actions_arbitrating' do
#
#   ORDER = MiddleAges.privileges
#   RULES = MiddleAges.rules
#
#   let(:person){
#     MiddleAges::Person.new 'person', 42,
#         MiddleAges::Person::MALE, nil
#   }
#   let(:woman){
#     MiddleAges::Person.new 'woman', 42,
#         MiddleAges::Person::FEMALE, nil
#   }
#   let(:child){
#     MiddleAges::Person.new 'child', 8,
#         MiddleAges::Person::MALE, nil
#   }
#
#   before{ test_person person }
#   def test_person value; @person = value; end
#
#   def privilege *args, context: nil
#     ORDER.get(*args).
#         tap{|p| p.dup_with_context context if context }
#   end
#
#   def rule scope, action, privilege
#     arbitration = Admission::Arbitration2.new RULES,
#         @person, action, scope
#     arbitration.rule_on privilege
#   end
#
#   describe 'actions' do
#
#     def actions_rule action, privilege
#       rule :actions, action, privilege
#     end
#
#     # sad times :-(
#     it 'asserts women are not equal to men' do
#       expect(
#           actions_rule :literally_anything, privilege(:human)
#       ).to be(true)
#
#       test_person woman
#       expect(
#           actions_rule :literally_anything, privilege(:human)
#       ).to be(false)
#     end
#
#   end
#
# end
