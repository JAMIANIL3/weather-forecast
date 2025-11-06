# frozen_string_literal: true

class GeocodingService
  # Converts an address or postal code to coordinates via Nominatim.
  # Returns { zip:, country:, lat:, lon:, display_name: }

  include HttpClient

  NOMINATIM_URL     = GEOCODING_ENDPOINTS[:search]
  USER_AGENT        = GEOCODING_USER_AGENT
  POSTAL_PATTERNS   = GEOCODING_POSTAL_PATTERNS

  # Initializes with input address text.
  def initialize(address)
    @address = address.to_s.strip
    validate_input!
  end

  # Performs API lookup and shapes result into a location hash.
  # Returns { lat:, lon:, display_name:, zip:, country: }
  def call
    location = geocode_address
    format_location(location)
  end

  # Class wrapper that returns a ServiceResult.
  def self.call(address)
    data = new(address).call
    ServiceResult.success(data)
  rescue => e
    ServiceResult.error(e.message)
  end

  private

  # Ensures address is present.
  def validate_input!
    raise ArgumentError, "Address is required" if @address.blank?
  end

  # Requests geocoding API and returns first match.
  # Raises if no address matches found.
  def geocode_address
    query = {
      q: @address,
      format: "json",
      addressdetails: 1,
      limit: 1
    }

    headers = { "User-Agent" => USER_AGENT }
    response = get_json(NOMINATIM_URL, query:, headers:)

    raise "No results found for address: #{@address}" if response.blank?

    result = response.first
    result["address"] ||= {}
    result
  end

  # Normalizes Nominatim data into the app's location structure.
  # Returns { lat:, lon:, display_name:, zip:, country: }
  def format_location(location)
    addr = location["address"]

    {
      lat:         location["lat"].to_f.round(4),
      lon:         location["lon"].to_f.round(4),
      display_name: location["display_name"],
      zip:         addr["postcode"] || extract_zip(@address),
      country:     addr["country_code"]&.upcase
    }.compact
  end

  # Extracts postal code from raw input using regex patterns.
  # Returns zip string or nil.
  def extract_zip(text)
    POSTAL_PATTERNS.each_value do |pattern|
      return text[pattern] if text.match?(pattern)
    end
    nil
  end
end
