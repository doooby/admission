class Admission::Denied < ::StandardError

  attr_reader :status, :request_args

  def initialize status, *request_args
    @status = status
    @request_args = request_args
  end

  def message
    'Admission denied.'
  end

end