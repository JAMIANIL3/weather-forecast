# frozen_string_literal: true

class GeocodingService
  # Resolves addresses to coordinates using Nominatim API.
  # Returns: { zip:, country:, lat:, lon:, display_name: }

  include HttpClient

  NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search'
  USER_AGENT = 'rails-weather-demo/1.0 (educational)'

  POSTAL_PATTERNS = {
    us: /\b\d{5}(?:-\d{4})?\b/,          # US ZIP (5) or ZIP+4 (5-4)
    india: /\b[1-9]\d{5}\b/,             # India PIN (6 digits)
    generic: /\b[A-Za-z0-9][A-Za-z0-9 \-]{1,8}[A-Za-z0-9]\b/ # Generic 3-10 chars
  }.freeze

  # @param address [String] free-form address or postal code
  def initialize(address)
    @address = address.to_s.strip
    validate_input!
  end

  # Instance entrypoint: performs the HTTP request and formats the result.
  # @return [Hash] formatted location data
  def call
    location = geocode_address
    format_location(location)
  end

  # Class-level convenience wrapper that returns a ServiceResult so callers
  # (for example controllers) get consistent return types and error handling.
  #
  # @param address [String]
  # @return [ServiceResult]
  def self.call(address)
    service = new(address)
    data = service.call
    ServiceResult.success(data)
  rescue StandardError => e
    ServiceResult.error(e.message)
  end

  private

  # Validate input early to avoid sending meaningless requests.
  def validate_input!
    raise ArgumentError, 'Address is required' if @address.blank?
  end

  # Perform the request against Nominatim and return the first result entry
  # (as parsed JSON). Raises on no results so callers receive a clear error.
    def geocode_address
      query = {
        q: @address,
        format: "json",
        addressdetails: 1,
        limit: 1
      }
      headers = { "User-Agent" => USER_AGENT }


    # debug: output the outgoing request parameters in test runs to help WebMock matching
    if Rails.env.test?
      puts "[GeocodingService] Requesting #{NOMINATIM_URL} with query=#{query.inspect} headers=#{headers.inspect}"
    end

      response = get_json(NOMINATIM_URL, query: query, headers: headers)

    raise "No results found for address: #{@address}" if response.blank? || response.empty?
      result = response.first
      
      # Handle missing fields
      result["address"] ||= {}
      result
    end

  # Convert the raw Nominatim result into the small hash shape the app uses.
  # @param location [Hash] raw parsed JSON from Nominatim
  # @return [Hash]
  def format_location(location)
    address_details = location["address"]
      result = {
      lat: location["lat"].to_f.round(4),
      lon: location["lon"].to_f.round(4),
        display_name: location["display_name"],
        zip: address_details["postcode"] || extract_zip(@address)
      }
      result[:country] = address_details["country_code"].to_s.upcase if address_details["country_code"]
      result
  end

  # Attempt to extract a postal code from the provided free-form text using
  # common patterns. Returns nil if no reasonable match is found.
  # @param text [String]
  # @return [String, nil]
  def extract_zip(text)
    POSTAL_PATTERNS.each_value do |pattern|
      if (match = text.match(pattern))
        return match[0]
      end
    end
    nil
  end
end
