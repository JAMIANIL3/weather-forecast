class WeatherController < ApplicationController
  def index; end

  def show
    result = fetch_weather_data
    render_weather_result(result)
  end

  private

  def fetch_weather_data
    return ServiceResult.error("Address required") if params[:address].blank?

    # Get location data
    geocoding_result = GeocodingService.call(params[:address])
    return geocoding_result if geocoding_result.error?

    location = geocoding_result.data

    # Get weather data with caching
    cache_key = "weather:#{location[:zip]}:v1"
    from_cache = true

    weather_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      from_cache = false
      weather_result = WeatherService.call(
        lat: location[:lat],
        lon: location[:lon],
        units: "metric"
      )
      return weather_result if weather_result.error?
      weather_result.data
    end

    ServiceResult.success(
      forecast: weather_data,
      place: location[:display_name],
      zip: location[:zip],
      from_cache: from_cache
    )
  rescue Redis::BaseError => e
    Rails.logger.error "Redis cache error: #{e.message}"
    # Fallback to direct API call if cache fails
    weather_result = WeatherService.call(
      lat: location[:lat],
      lon: location[:lon],
      units: "metric"
    )
    return weather_result if weather_result.error?

    ServiceResult.success(
      forecast: weather_result.data,
      place: location[:display_name],
      zip: location[:zip],
      from_cache: false
    )
  end

  def render_weather_result(result)
    if result.success?
      # expose as instance variables so controller specs can inspect view_assigns
      @forecast = result.data[:forecast]
      @place = result.data[:place]
      @zip = result.data[:zip]
      @from_cache = result.data[:from_cache]
      @error = nil

      render partial: "weather/result", locals: {
        forecast: @forecast,
        place: @place,
        zip: @zip,
        from_cache: @from_cache,
        error: @error
      }
    else
      @error = result.error
      @forecast = @place = @zip = @from_cache = nil
      render partial: "weather/result", locals: { error: @error }
    end
  end
end
