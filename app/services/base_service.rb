module BaseService
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
  end

  class_methods do
    def call(...)
      new(...).call
    end
  end

  def call
    if valid?
      perform
    else
      fail!(errors.full_messages.join(", "))
    end
  rescue StandardError => e
    fail!(e.message)
  end

  private

  def fail!(message)
    ServiceResult.error(message)
  end

  def success(data = {})
    ServiceResult.success(data)
  end
end