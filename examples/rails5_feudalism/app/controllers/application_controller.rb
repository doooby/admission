class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  require 'admission/rails'
  include Admission::Rails::ControllerAddon

  def request_admission! action, scope
    @requested_admission = {action: action, scope: scope}
    puts "ADMISSION: #{action} over  #{scope}"
  end

end
