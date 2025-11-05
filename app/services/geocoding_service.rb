# frozen_string_literal: true

class GeocodingService
  include HttpClient

  NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
  USER_AGENT = "rails-weather-demo/1.0 (educational)"

  # Postal code patterns for various countries
  POSTAL_PATTERNS = {
    us: /\b\d{5}(?:-\d{4})?\b/,          # US ZIP (5) or ZIP+4 (5-4)
    india: /\b[1-9]\d{5}\b/,             # India PIN (6 digits)
    generic: /\b[A-Za-z0-9][A-Za-z0-9 \-]{1,8}[A-Za-z0-9]\b/ # Generic 3-10 chars
  }.freeze

  def initialize(address)
    @address = address.to_s.strip
    validate_input!
  end

  def call
    location = geocode_address
    format_location(location)
  end

  # Class-level convenience wrapper that returns a ServiceResult
  def self.call(address)
    service = new(address)
    data = service.call
    ServiceResult.success(data)
  rescue StandardError => e
    ServiceResult.error(e.message)
  end

  private

  def validate_input!
    raise ArgumentError, "Address is required" if @address.blank?
  end

  def geocode_address
    response = get_json(
      NOMINATIM_URL,
      query: {
        q: @address,
        format: "json",
        addressdetails: 1,
        limit: 1
      },
      headers: { "User-Agent" => USER_AGENT }
    )

    raise "Address not found" if response.blank?
    response.first
  end

  def format_location(location)
    address_details = location["address"] || {}
    {
      zip: extract_zip(@address) || address_details["postcode"].to_s,
      country: address_details["country_code"].to_s.upcase,
      lat: location["lat"],
      lon: location["lon"],
      display_name: location["display_name"]
    }
  end

  def extract_zip(text)
    POSTAL_PATTERNS.each_value do |pattern|
      if (match = text.match(pattern))
        return match[0]
      end
    end
    nil
  end
end
