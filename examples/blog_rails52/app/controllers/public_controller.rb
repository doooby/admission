class PublicController < ApplicationController

  skip_before_action :assure_admission

  def index
  end

  def login
    user = User.find params[:user_id]
    session[:user_id] = user.id
    redirect_to root_path
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path
  end

end
