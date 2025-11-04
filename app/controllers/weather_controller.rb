class WeatherController < ApplicationController
  def index; end

  def show
    @address = params[:address].to_s.strip
    if @address.blank?
      redirect_to root_path, alert: "Please enter an address." and return
    end

    geo = GeocodingService.new(@address).call
    if geo[:zip].blank?
      redirect_to root_path, alert: "Couldn't find a ZIP/Postal code for that address." and return
    end

    @zip       = geo[:zip]
    @place     = geo[:display_name]
    units      = "metric" # change to "imperial" if you prefer °F
    cache_key  = "forecast:v1:#{@zip}:#{units}"

    from_cache = true
    @forecast = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      from_cache = false
      WeatherService.new(lat: geo[:lat], lon: geo[:lon], units: units).call
    end
    @from_cache = from_cache
  rescue => e
    redirect_to root_path, alert: "Error: #{e.message}"
  end
end
