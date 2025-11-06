module BaseService
  # Service object mixin with validations. Implement `perform` and add
  # ActiveModel validations for input checking.

  class_methods do
    # Convenience class-level constructor + call so callers can use:
    #   MyService.call(args)
    # which returns a `ServiceResult`.
    def call(...)
      new(...).call
    end
  end

  # Entry point for instances. Validates the object and runs `perform`.
  # Any raised StandardError is captured and returned as a failed
  # ServiceResult to keep controllers simple.
  #
  # Returns a ServiceResult instance.
  def call
    if valid?
      perform
    else
      fail!(errors.full_messages.join(', '))
    end
  rescue StandardError => e
    # Convert unexpected exceptions into a ServiceResult.error so callers
    # receive a consistent return type.
    fail!(e.message)
  end

  private

  # Build a failure ServiceResult with a message.
  # @param message [String]
  # @return [ServiceResult]
  def fail!(message)
    ServiceResult.error(message)
  end

  # Build a success ServiceResult containing optional data.
  # @param data [Hash, Object] optional payload
  # @return [ServiceResult]
  def success(data = {})
    ServiceResult.success(data)
  end
end