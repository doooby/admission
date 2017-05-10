class Admission::Denied < ::StandardError

  attr_reader :status, :request_args
  attr_accessor :message

  def initialize status, *request_args
    @status = status
    @request_args = request_args
  end

  def to_s
    @message || 'Admission denied.'
  end

end