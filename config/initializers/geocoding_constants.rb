# frozen_string_literal: true

# Configure Nominatim API settings and supported postal code patterns.
# These can be overridden using environment variables for different deployments.

GEOCODING_ENDPOINTS = {
  search: ENV.fetch("NOMINATIM_SEARCH_URL", "https://nominatim.openstreetmap.org/search")
}.freeze

GEOCODING_USER_AGENT = ENV.fetch(
  "NOMINATIM_USER_AGENT",
  "rails-weather-demo/1.0 (educational)"
).freeze

GEOCODING_POSTAL_PATTERNS = {
  us:      /\b\d{5}(?:-\d{4})?\b/,              # US ZIP or ZIP+4
  india:   /\b[1-9]\d{5}\b/,                    # India 6-digit PIN
  generic: /\b[A-Za-z0-9][A-Za-z0-9 \-]{1,8}[A-Za-z0-9]\b/ # Fallback for other regions
}.freeze
