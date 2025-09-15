class Client
  attr_reader :options

  def initialize(options = {})
    @options = options
  end

  def get(url) end
end
