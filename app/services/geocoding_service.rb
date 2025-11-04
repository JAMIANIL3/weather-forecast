# frozen_string_literal: true
require "httparty"

class GeocodingService
  NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"

  def initialize(address)
    @address = address.to_s
  end

  def call
    # 1) If the user typed a postal code in the address, prefer that (US 5/9, India 6, generic 3-10 mix)
    zip = extract_zip(@address)

    # 2) Geocode to get lat/lon and (if missing) postal code
    resp = HTTParty.get(
      NOMINATIM_URL,
      query: {
        q: @address,
        format: "json",
        addressdetails: 1,
        limit: 1
      },
      headers: { "User-Agent" => "rails-weather-demo/1.0 (educational)" }
    )

    raise StandardError, "Address not found" if resp.parsed_response.blank?

    rec = resp.parsed_response.first
    addr = rec["address"] || {}

    {
      zip: zip || addr["postcode"].to_s,
      country: addr["country_code"].to_s.upcase,
      lat: rec["lat"],
      lon: rec["lon"],
      display_name: rec["display_name"]
    }
  end

  private

  def extract_zip(text)
    t = text.strip

    # Common patterns
    # US ZIP (5) or ZIP+4 (5-4)
    return Regexp.last_match(0) if t =~ /\b\d{5}(?:-\d{4})?\b/
    # India PIN (6 consecutive digits starting 1-9)
    return Regexp.last_match(0) if t =~ /\b[1-9]\d{5}\b/
    # Generic fallback: 3–10 alnum (captures many countries like UK/CA when typed cleanly)
    return Regexp.last_match(0) if t =~ /\b[A-Za-z0-9][A-Za-z0-9 \-]{1,8}[A-Za-z0-9]\b/

    nil
  end
end
