# frozen_string_literal: true

# Configure default endpoints and valid units for the weather integration.
# These can be overridden via environment variables in different deploys.

WEATHER_ENDPOINTS = {
  weather: ENV.fetch("OPENWEATHER_WEATHER_URL", "https://api.openweathermap.org/data/2.5/weather"),
  forecast: ENV.fetch("OPENWEATHER_FORECAST_URL", "https://api.openweathermap.org/data/2.5/forecast")
}.freeze

WEATHER_VALID_UNITS = ENV.fetch("WEATHER_VALID_UNITS", "metric,imperial").split(",").map(&:strip).freeze
