require 'test_helper'

class Admission::ScopesTest < ActiveSupport::TestCase

  define_method :users_mock, &(
    Admission::Tests::ActionHelper.mock UsersController
  )

  test 'new -> users' do
    admission_action_mock UsersController do |action|
      action.action = :new
      action.assert :users
    end
  end

  test 'create -> users' do
    users_mock do |action|
      assert_equal :users, action.(:create)
    end
  end

  test 'edt -> users' do
    admission_action_mock UsersController do |action|
      user = users :user1
      action.action = :edit
      action.params = {id: user.id}
      action.assert user
    end
  end

  test 'update -> users' do
    users_mock do |action|
      user = users :user1
      assert_equal user, action.(:update, {id: user.id})
    end
  end

end
