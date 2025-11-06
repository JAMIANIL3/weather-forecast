class WeatherController < ApplicationController

  def index; end

  # GET /weather expecting `params[:address]`.
  def show
    result = fetch_weather_data
    render_weather_result(result)
  end

  private

  # To Fetch weather Data based on the address
  # Returns:
  #   ServiceResult(success: true, data: {...})
  #   ServiceResult(success: false, error: "message")
  def fetch_weather_data
    return ServiceResult.error("Address required") if params[:address].blank?

    # Geocode the location
    geocoding_result = GeocodingService.call(params[:address])
    return geocoding_result if geocoding_result.error?

    location = geocoding_result.data

    result = WeatherService.fetch_with_cache(lat:  location[:lat], lon:  location[:lon], zip:  location[:zip], units: "metric")
    return result if result.error?

    result.data[:place] = location[:display_name]
    result.data[:zip] = location[:zip]
    result
  end

  # Render the partial with proper locals
  #
  # @param result [ServiceResult]
  def render_weather_result(result)
    if result.success?
      data = result.data

      render partial: "weather/result", locals: {
        forecast:   data[:forecast],
        place:      data[:place],
        zip:        data[:zip],
        from_cache: data[:from_cache],
        error:      nil,
        cache_key:  data[:cache_key]
      }
    else
      render partial: "weather/result", locals: { error: result.error }
    end
  end
end
