module HttpClient
  extend ActiveSupport::Concern

  included do
    include HTTParty
    include ActiveModel::Validations
  end

  private

  def get_json(url, options = {})
    validate_response!(self.class.get(url, options))
  end

  def validate_response!(response)
    return response.parsed_response if response.success?

    case response.code
    when 401, 403
      raise ApiError, "Authentication failed"
    when 404
      raise ApiError, "Resource not found"
    when 429
      raise ApiError, "Rate limit exceeded"
    else
      raise ApiError, "API error: #{response.code} - #{response.message}"
    end
  end

  class ApiError < StandardError; end
end