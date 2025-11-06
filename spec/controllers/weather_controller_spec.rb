require "rails_helper"

RSpec.describe WeatherController, type: :controller do
  render_views
  describe "GET #index" do
    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    let(:address) { "10001" }

    let(:geo_result) do
      ServiceResult.success(
        lat: 40.7506,
        lon: -73.9971,
        display_name: "New York, NY 10001",
        zip: "10001"
      )
    end

    let(:weather_data) do
      {
        current: { temp: 20, humidity: 65 },
        today: { min: 18, max: 22 },
        next_days: []
      }
    end

    let(:success_result_live) do
      ServiceResult.success(
        forecast: weather_data,
        from_cache: false,
        cache_key: "weather:10001:v1"
      )
    end

    let(:success_result_cache) do
      ServiceResult.success(
        forecast: weather_data,
        from_cache: true,
        cache_key: "weather:10001:v1"
      )
    end

    let(:success_geo) do
      ServiceResult.success(
        lat: 40.7506,
        lon: -73.9971,
        display_name: "New York, NY 10001",
        zip: "10001"
      )
    end

    let(:success_weather_live) do
      ServiceResult.success(
        current: { temp: 20, humidity: 65 },
        today: { min: 18, max: 22 },
        next_days: []
      )
    end

    context "when address is missing" do
      it "renders error" do
        get :show
        expect(response.body).to include("Address required")
      end
    end

    context "when address is valid" do
      before do
        allow(GeocodingService).to receive(:call)
          .with(address)
          .and_return(geo_result)
      end

      it "renders live weather data when cache misses" do
        allow(WeatherService).to receive(:fetch_with_cache)
          .and_return(success_result_live)

        get :show, params: { address: address }

        expect(response).to render_template(partial: "weather/_result")
        expect(response.body).to include("New York, NY 10001") # place
        expect(response.body).to include("20") # temp
        expect(response.body).to include("Live") # your UI might show Fresh 🌟 etc.

        # ✅ Ensures service was hit
        expect(WeatherService).to have_received(:fetch_with_cache)
      end

      it "renders cached data when cache hits" do
        allow(WeatherService).to receive(:fetch_with_cache)
          .and_return(success_result_cache)

        get :show, params: { address: address }

        expect(response).to render_template(partial: "weather/_result")
        expect(response.body).to include("New York, NY 10001")
        expect(response.body).to include("20")
        expect(response.body).to include("Cached") # ✅ what your UI prints
      end

      it "falls back when Redis fails" do
        allow(GeocodingService).to receive(:call)
          .with(address)
          .and_return(success_geo)

        allow(Rails.cache).to receive(:fetch).and_raise(Redis::BaseError.new("Redis down"))

        stub_request(:get, /api.openweathermap.org/)
          .to_return(
            status: 200,
            body: {
              main: { temp: 20, feels_like: 18, humidity: 65, temp_min: 18, temp_max: 22 },
              wind: { speed: 5 },
              weather: [{ description: "clear sky", main: "Clear" }],
              list: []
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        get :show, params: { address: address }

        expect(response).to render_template(partial: "weather/_result")
        expect(assigns(:from_cache)).to eq(nil)
      end
    end
  end
end
