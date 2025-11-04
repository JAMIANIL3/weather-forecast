class WeatherController < ApplicationController
  def index; end

  def show
    address = params[:address].to_s.strip

    return render partial: "weather/result", locals: { error: "Address required" } if address.blank?

    begin
      geo = GeocodingService.new(address).call
    rescue
      return render partial: "weather/result", locals: { error: "Could not locate address. Try again." }
    end

    zip = geo[:zip]
    place = geo[:display_name]

    cache_key = "weather:#{zip}"
    from_cache = true

    forecast = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      from_cache = false
      WeatherService.new(lat: geo[:lat], lon: geo[:lon]).call
    end

    # puts "I am here \n #{place} \n #{zip} \n #{forecast.inspect} \n#{from_cache}"
    render partial: "weather/result", locals: {
      place: place,
      zip: zip,
      forecast: forecast,
      from_cache: from_cache,
      error: nil
    }
  end
end
