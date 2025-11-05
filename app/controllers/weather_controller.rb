class WeatherController < ApplicationController
  # Controller responsible for the public weather UI.
  #
  # Routes handled:
  # - index: serves the search UI
  # - show: returns the partial with the latest weather result for a given address

  def index; end

  # GET /weather or similar route expecting `params[:address]`.
  # Fetches geocoded location, then weather (from cache when available), and
  # renders the partial with the result.
  def show
    result = fetch_weather_data
    render_weather_result(result)
  end

  private

  # Orchestrates retrieving the location and weather data and returns a
  # ServiceResult. Handles cache lookup and fallback to the weather API on
  # cache errors.
  def fetch_weather_data
    return ServiceResult.error('Address required') if params[:address].blank?

    geocoding_result = GeocodingService.call(params[:address])
    return geocoding_result if geocoding_result.error?

    location = geocoding_result.data

    cache_key = "weather:#{location[:zip]}:v1"
    from_cache = true

    weather_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      from_cache = false
      weather_result = WeatherService.call(
        lat: location[:lat],
        lon: location[:lon],
        units: 'metric'
      )
      return weather_result if weather_result.error?
      weather_result.data
    end

    ServiceResult.success(
      forecast: weather_data,
      place: location[:display_name],
      zip: location[:zip],
      from_cache: from_cache,
      cache_key: cache_key
    )
  rescue Redis::BaseError => e
    # If the cache layer fails, log and fall back to a direct weather lookup.
    Rails.logger.error "Redis cache error: #{e.message}"
    weather_result = WeatherService.call(
      lat: location[:lat],
      lon: location[:lon],
      units: 'metric'
    )
    return weather_result if weather_result.error?

    ServiceResult.success(
      forecast: weather_result.data,
      place: location[:display_name],
      zip: location[:zip],
      from_cache: false,
      cache_key: cache_key
    )
  end

  # Given a ServiceResult, sets view instance variables and renders the
  # `weather/result` partial. This keeps the view rendering logic isolated
  # in one place and makes controller specs simpler to assert on instance
  # variables.
  #
  # @param result [ServiceResult]
  def render_weather_result(result)
    if result.success?
      # expose as instance variables so controller specs can inspect view_assigns
      @forecast = result.data[:forecast]
      @place = result.data[:place]
      @zip = result.data[:zip]
      @from_cache = result.data[:from_cache]
      @error = nil
      @cache_key = result.data[:cache_key]

      render partial: 'weather/result', locals: {
        forecast: @forecast,
        place: @place,
        zip: @zip,
        from_cache: @from_cache,
        error: @error,
        cache_key: @cache_key
      }
    else
      @error = result.error
      @forecast = @place = @zip = @from_cache = nil
      render partial: 'weather/result', locals: { error: @error }
    end
  end
end
