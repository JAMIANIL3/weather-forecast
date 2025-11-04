# frozen_string_literal: true
require "httparty"

class WeatherService
  WEATHER_URL  = "https://api.openweathermap.org/data/2.5/weather"
  FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast"

  def initialize(lat:, lon:, units: "metric")
    @lat   = lat
    @lon   = lon
    @units = units
    @api   = ENV.fetch("OPENWEATHER_API_KEY")
  end

  def call
    current_resp = HTTParty.get(
      WEATHER_URL,
      query: { lat: @lat, lon: @lon, units: @units, appid: @api }
    )

    forecast_resp = HTTParty.get(
      FORECAST_URL,
      query: { lat: @lat, lon: @lon, units: @units, appid: @api }
    )

    raise "Weather API error" unless current_resp.success?
    raise "Forecast API error" unless forecast_resp.success?

    # Parse current
    current = current_resp.parsed_response
    today_data = current["main"]

    # Next 3 days (8 records per day, 3 hours interval)
    daily_groups = forecast_resp["list"].group_by { |x| Time.at(x["dt"]).to_date }
    next_days = daily_groups.keys.sort[1, 3].map do |day|
      day_records = daily_groups[day]
      temps = day_records.map { |d| d.dig("main", "temp") }.compact
      {
        date: day,
        high: temps.max,
        low:  temps.min,
        summary: day_records.first.dig("weather",0,"main")
      }
    end

    {
      current: {
        temp: today_data["temp"],
        feels_like: today_data["feels_like"],
        humidity: today_data["humidity"],
        wind_speed: current["wind"]["speed"],
        description: current.dig("weather", 0, "description")
      },
      today: {
        high: today_data["temp_max"],
        low:  today_data["temp_min"]
      },
      next_days: next_days
    }
  end
end
