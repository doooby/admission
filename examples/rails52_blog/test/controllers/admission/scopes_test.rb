require 'test_helper'

class Admission::ScopesTest < ActiveSupport::TestCase

  ###
  # ArticlesController
  ###

  define_method :articles_mock, &(
    Admission::Tests::ActionHelper.mock ArticlesController
  )

  test 'articles#show, edit, update' do
    article = articles :articleB1
    articles_mock do |action|
      assert_equal article, action.(:show, {id: article.id})
      assert_equal article, action.(:edit, {id: article.id})
      assert_equal article, action.(:update, {id: article.id})
    end
  end

  test 'articles#new, create' do
    articles_mock do |action|
      assert_equal :articles, action.(:new)
      assert_equal :articles, action.(:create)
    end
  end

  test 'articles#create_message' do
    article = articles :articleB1
    articles_mock do |action|
      assert_equal [article, :messages], action.(:create_message, {id: article.id})
    end
  end

  ###
  # UsersController
  ###

  define_method :users_mock, &(
    Admission::Tests::ActionHelper.mock UsersController
  )

  test 'users#new' do
    admission_action_mock UsersController do |action|
      action.action = :new
      action.assert :users
    end
  end

  test 'users#create' do
    users_mock do |action|
      assert_equal :users, action.(:create)
    end
  end

  test 'users#edit' do
    admission_action_mock UsersController do |action|
      user = users :user1
      action.action = :edit
      action.params = {id: user.id}
      action.assert user
    end
  end

  test 'users#update' do
    users_mock do |action|
      user = users :user1
      assert_equal user, action.(:update, {id: user.id})
    end
  end

end
