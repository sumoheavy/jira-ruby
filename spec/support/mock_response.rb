class Response
  attr_reader :body, :status

  def initialize(body, status = nil)
    @body = body
    @status = status
  end
end
