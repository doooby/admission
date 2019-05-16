require 'test_helper'

class Admission::RulesTest < ActiveSupport::TestCase

  PRIVILEGES = Admission::Tests.all_privileges

  def user_status
    User.new.status
  end

  test 'show -> articles' do
    assert_admission_rule user_status, :show, :articles, PRIVILEGES
  end

  test 'new, create -> articles' do
    status = user_status 
    %i[new create].each do |request|
      assert_admission_rule status, request, :articles, PRIVILEGES.select('author')
      refute_admission_rule status, request, :articles, PRIVILEGES.reject('author')
    end
  end

  test 'edit, update -> articles' do
    %i[edit update].each do |request|

      admission_rule request do |rule|
        rule.status = users(:authorA).status
        rule.scope = articles :articleA2
        rule.to_assert = PRIVILEGES.select('author')
        rule.to_refute = PRIVILEGES.reject('author')
        rule.assert
      end

      admission_rule request do |rule|
        rule.status = users(:authorB).status
        rule.scope = articles :articleA2
        rule.to_refute = PRIVILEGES
        rule.assert
      end

    end
  end

  test 'create_message -> articles:messages' do
    assert_admission_rule user_status, :create_message, [Article.new, :messages], PRIVILEGES
  end

  test 'new, create, edit, update -> users' do
    status = user_status 
    admin, others = PRIVILEGES.partition 'admin'

    %i[new create edit update].each do |request|
      assert_admission_rule status, request, :users, admin
      refute_admission_rule status, request, :users, others
    end
  end

end
