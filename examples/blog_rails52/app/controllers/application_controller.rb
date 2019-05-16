class ApplicationController < ActionController::Base

  include Admission::Rails::ControllerAddon

  rescue_from Admission::Denied do |exception|
    Rails.logger.warn "Admission denied."
    redirect_to root_path, notice: exception.message
  end

  helper_method :current_user

  private

  def current_user
    unless defined?(@current_user)
      user_id = session[:user_id]
      @current_user = (User.find user_id if user_id)
    end
    @current_user
  end

  def enforce_user_presence
    redirect_to root_path, notice: 'Use must log in first.' unless current_user
  end

end
