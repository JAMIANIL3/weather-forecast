module HttpClient
  # HTTP client with JSON GET helper and error handling
  
  extend ActiveSupport::Concern

  included do
    include HTTParty
    include ActiveModel::Validations
  end

  MAX_RETRIES = 2

  private

  # Perform a GET request and return the parsed JSON on success. Any non-2xx
  # response will raise an ApiError with a descriptive message.
  #
  # @param url [String] full URL to request
  # @param options [Hash] HTTParty options (e.g., query:, headers:)
  # @return [Hash, Array] Parsed JSON structure
  # @raise [ApiError]
  def get_json(url, options = {})
    attempts = 0

    begin
      response = self.class.get(url, options)
      validate_response!(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      attempts += 1
      Rails.logger.error("[HttpClient] Network error #{e.class}: #{e.message} → #{url}") if defined?(Rails)

      retry if attempts <= MAX_RETRIES

      raise ApiError, "Couldn't fetch the data at the moment"
    end
  end


  # Inspect the HTTParty response and either return the parsed JSON or raise
  # an ApiError with a helpful message. Specific HTTP response codes are
  # mapped to clearer errors for easier handling upstream.
  #
  # @param response [HTTParty::Response]
  # @return [Hash, Array]
  # @raise [ApiError]
  def validate_response!(response)
    return response.parsed_response if response.success?

    case response.code
    when 401, 403
      raise ApiError, 'Authentication failed'
    when 404
      raise ApiError, 'Resource not found'
    when 429
      raise ApiError, 'Rate limit exceeded'
    else
      raise ApiError, "API error: #{response.code} - #{response.message}"
    end
  end

  # Generic API error raised by the helper methods above
  class ApiError < StandardError; end
end