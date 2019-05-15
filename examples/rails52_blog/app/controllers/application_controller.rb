class ApplicationController < ActionController::Base

  include Admission::Rails::ControllerAddon

  rescue_from Admission::Denied do |exception|
    Rails.logger.warn "Admission denied."
    render 'public/denied', locals: {exception: exception}
  end

  helper_method :current_user

  def current_user
    unless defined?(@current_user)
      user_id = session[:user_id]
      @current_user = (User.find user_id if user_id)
    end
    @current_user
  end

end
