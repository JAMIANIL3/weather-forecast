class ServiceResult
  # Success/error result wrapper with optional data or error message
  attr_reader :success, :data, :error

  # @param success [Boolean]
  # @param data [Object, nil]
  # @param error [String, nil]
  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  # Build a successful ServiceResult
  # @param data [Object, nil] optional payload
  # @return [ServiceResult]
  def self.success(data = nil)
    new(success: true, data: data)
  end

  # Build a failed ServiceResult with an error message
  # @param message [String]
  # @return [ServiceResult]
  def self.error(message)
    new(success: false, error: message)
  end

  # Predicate for success
  # @return [Boolean]
  def success?
    @success
  end

  # Predicate for error (inverse of success?)
  # @return [Boolean]
  def error?
    !success?
  end
end