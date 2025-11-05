# frozen_string_literal: true

class WeatherService
  # Fetches and normalizes weather data from OpenWeather API.
  # Returns: { current:, today:, next_days: [] }

  include HttpClient

  WEATHER_URL  = WEATHER_ENDPOINTS[:weather]
  FORECAST_URL = WEATHER_ENDPOINTS[:forecast]
  VALID_UNITS = WEATHER_VALID_UNITS

  def initialize(lat:, lon:, units: 'metric')
    @lat = lat.to_f
    @lon = lon.to_f
    @units = units
    @api_key = ENV.fetch('OPENWEATHER_API_KEY')
    validate_input!
  end

  def self.call(lat:, lon:, units: 'metric')
    service = new(lat: lat, lon: lon, units: units)
    data = service.call
    ServiceResult.success(data)
  rescue StandardError => e
    ServiceResult.error(e.message)
  end

  # Execute the two upstream requests (current weather and forecast), then
  # normalize and return a Ruby hash. Raises a wrapped error message for
  # ApiError so callers can surface a friendly message.
  #
  # @return [Hash]
  def call
    current_resp = get_json(WEATHER_URL, query: api_params)
    forecast_resp = get_json(FORECAST_URL, query: api_params)

    {
      current: extract_current_weather(current_resp),
      today: extract_today_forecast(current_resp),
      next_days: extract_next_days(forecast_resp)
    }
  rescue ApiError => e
    raise "Weather service error: #{e.message}"
  end

  private

  # Basic input validation for coordinates and units. Raises for invalid
  # inputs so the error propagates as a ServiceResult.error in callers.
  def validate_input!
    raise ArgumentError, 'Latitude is required' if @lat.nil? || @lat.abs > 90
    raise ArgumentError, 'Longitude is required' if @lon.nil? || @lon.abs > 180
    raise ArgumentError, 'Invalid units (use metric or imperial)' unless VALID_UNITS.include?(@units)
  end

  def extract_current_weather(data)
    {
      temp: data.dig('main', 'temp'),
      feels_like: data.dig('main', 'feels_like'),
      humidity: data.dig('main', 'humidity'),
      wind_speed: data.dig('wind', 'speed'),
      description: data.dig('weather', 0, 'description')
    }
  end

  # Pull out today's high/low from the current response payload
  # @param data [Hash]
  # @return [Hash]
  def extract_today_forecast(data)
    {
      high: data.dig('main', 'temp_max'),
      low: data.dig('main', 'temp_min')
    }
  end

  # Build a short array of day forecasts from the 3-hourly forecast payload
  # @param data [Hash]
  # @return [Array<Hash>]
  def extract_next_days(data)
    daily_groups = data['list'].group_by { |x| Time.at(x['dt']).to_date }
    # Skip the current day and take the next 3 days
    daily_groups.keys.sort[1, 3].map do |day|
      build_day_forecast(daily_groups[day])
    end
  end

  # Build a single day's summary from the grouped 3-hour records
  # @param records [Array<Hash>]
  # @return [Hash]
  def build_day_forecast(records)
    temps = records.map { |d| d.dig('main', 'temp') }.compact
    {
      date: Time.at(records.first['dt']).to_date,
      high: temps.max,
      low: temps.min,
      summary: records.first.dig('weather', 0, 'main')
    }
  end

  # Parameters sent to the upstream API
  # @return [Hash]
  def api_params
    {
      lat: @lat,
      lon: @lon,
      units: @units,
      appid: @api_key
    }
  end
end
