# frozen_string_literal: true

class WeatherService
  # Fetches and normalizes weather data from OpenWeather API.

  include HttpClient

  WEATHER_URL  = WEATHER_ENDPOINTS[:weather]
  FORECAST_URL = WEATHER_ENDPOINTS[:forecast]
  VALID_UNITS  = WEATHER_VALID_UNITS
  CACHE_EXPIRY = 30.minutes

  # Initializes service with coordinates and unit settings.
  def initialize(lat:, lon:, units: "metric")
    @lat = lat.to_f
    @lon = lon.to_f
    @units = units
    @api_key = ENV.fetch("OPENWEATHER_API_KEY", "test_api_key")
    validate_input!
  end

  # Fetches weather data immediately (no cache).
  # Returns ServiceResult(success?, data/error)
  def self.call(lat:, lon:, units: "metric")
    data = new(lat: lat, lon: lon, units: units).call
    ServiceResult.success(data)
  rescue => e
    ServiceResult.error(e.message)
  end

  # Fetches weather data using Redis cache if available.
  # Returns ServiceResult with keys:
  #   :forecast => weather hash
  #   :from_cache => bool
  #   :cache_key => string
  def self.fetch_with_cache(lat:, lon:, zip:, units: "metric")
    cache_key = "weather:#{zip}:v1"
    from_cache = true

    begin
      weather_data = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
        from_cache = false
        new(lat: lat, lon: lon, units: units).call
      end

      ServiceResult.success(
        forecast: weather_data,
        from_cache: from_cache,
        cache_key: cache_key
      )

    rescue Redis::BaseError => e
      Rails.logger.error "Redis unavailable: #{e.message}"
      data = new(lat: lat, lon: lon, units: units).call

      ServiceResult.success(
        forecast: data,
        from_cache: false,
        cache_key: cache_key
      )

    rescue => e
      ServiceResult.error(e.message)
    end
  end

  # Calls OpenWeather API and builds normalized forecast hash.
  # Returns { current:, today:, next_days: [] }
  def call
    current  = get_json(WEATHER_URL,  query: api_params)
    forecast = get_json(FORECAST_URL, query: api_params)

    {
      current: extract_current_weather(current),
      today: extract_today_forecast(current),
      next_days: extract_next_days(forecast)
    }
  rescue ApiError => e
    raise "Weather service error: #{e.message}"
  end

  private

  # Validates coordinates and units.
  def validate_input!
    raise ArgumentError, "Invalid latitude"  if @lat.nil? || @lat.abs > 90
    raise ArgumentError, "Invalid longitude" if @lon.nil? || @lon.abs > 180
    raise ArgumentError, "Invalid units" unless VALID_UNITS.include?(@units)
  end

  # Extracts current weather values.
  # Returns { temp:, feels_like:, humidity:, wind_speed:, description: }
  def extract_current_weather(data)
    {
      temp:        data.dig("main", "temp"),
      feels_like:  data.dig("main", "feels_like"),
      humidity:    data.dig("main", "humidity"),
      wind_speed:  data.dig("wind", "speed"),
      description: data.dig("weather", 0, "description")
    }
  end

  # Extracts today's high/low temp.
  # Returns { high:, low: }
  def extract_today_forecast(data)
    {
      high: data.dig("main", "temp_max"),
      low:  data.dig("main", "temp_min")
    }
  end

  # Extracts next 3 days weather summary from 3-hour forecast.
  # Returns array of hashes [{ date:, high:, low:, summary: }]
  def extract_next_days(data)
    list = data["list"] || []
    return [] if list.empty?

    daily_groups = list.group_by { |x| Time.at(x["dt"]).to_date }
    days = daily_groups.keys.sort[1, 3] || []

    days.map { |day| build_day_forecast(daily_groups[day]) }
  end

  # Builds forecast for a single day.
  # Returns { date:, high:, low:, summary: }
  def build_day_forecast(records)
    temps = records.map { |d| d.dig("main", "temp") }.compact

    {
      date:    Time.at(records.first["dt"]).to_date,
      high:    temps.max,
      low:     temps.min,
      summary: records.first.dig("weather", 0, "main")
    }
  end

  # API query params
  def api_params
    { lat: @lat, lon: @lon, units: @units, appid: @api_key }
  end
end
