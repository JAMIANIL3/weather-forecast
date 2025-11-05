class ServiceResult
  attr_reader :success, :data, :error

  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.error(message)
    new(success: false, error: message)
  end

  def success?
    @success
  end

  def error?
    !success?
  end
end