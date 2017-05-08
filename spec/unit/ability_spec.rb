# require_relative '../spec_helper'
# require_relative '../test_context/index'
#
# RSpec.describe Admission::Ability do
#
#   let(:nobody_ability){ Admission::Ability.new Person::FIXTURES[:nobody] }
#   let(:haramber_ability){ Admission::Ability.new Person::FIXTURES[:harambe] }
#
#
#   describe '#new' do
#
#     it 'creates instance with no privileges' do
#       expect(nobody_ability.instance_variable_get :@no_privileges).to be
#     end
#
#     it 'creates instance with some privileges' do
#       expect(haramber_ability.instance_variable_get :@no_privileges).not_to be
#     end
#
#   end
#
#   # describe '#process' do
#   #
#   #   it '' do
#   #   end
#   #
#   # end
#
# end