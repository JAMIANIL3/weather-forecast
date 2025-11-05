require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #show' do
    let(:address) { '10001' }
    let(:geocoding_response) do
      ServiceResult.success({
        lat: 40.7506,
        lon: -73.9971,
        display_name: 'New York, NY 10001',
        zip: '10001'
      })
    end
    let(:weather_response) do
      ServiceResult.success({
        current: { temp: 20, humidity: 65 },
        today: { min: 18, max: 22 },
        next_days: []
      })
    end

    context 'when address is not provided' do
      it 'renders error in the result partial' do
        get :show
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'weather/_result')
        expect(controller.view_assigns['error']).to eq('Address required')
      end
    end

    context 'when address is provided' do
      before do
        allow(GeocodingService).to receive(:call).with(address).and_return(geocoding_response)
        allow(WeatherService).to receive(:call).with(
          lat: 40.7506,
          lon: -73.9971,
          units: 'metric'
        ).and_return(weather_response)
        allow(Rails.cache).to receive(:fetch).and_yield
      end

      it 'renders weather data in the result partial' do
        get :show, params: { address: address }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'weather/_result')
        expect(controller.view_assigns['place']).to eq('New York, NY 10001')
        expect(controller.view_assigns['forecast']).to be_present
      end

      context 'when caching is working' do
        it 'uses cached data when available' do
          allow(Rails.cache).to receive(:fetch).and_return({
            current: { temp: 20, humidity: 65 },
            today: { min: 18, max: 22 },
            next_days: []
          })
          get :show, params: { address: address }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(partial: 'weather/_result')
          expect(controller.view_assigns['from_cache']).to be true
        end
      end

      context 'when Redis is down' do
        before do
          allow(Rails.cache).to receive(:fetch).and_raise(Redis::BaseError)
        end

        it 'falls back to direct API call' do
          get :show, params: { address: address }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(partial: 'weather/_result')
          expect(controller.view_assigns['forecast']).to be_present
          expect(controller.view_assigns['from_cache']).to be false
        end
      end
    end
  end
end