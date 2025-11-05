require 'rails_helper'

RSpec.describe WeatherService do
  let(:valid_lat) { 40.7506 }
  let(:valid_lon) { -73.9971 }
  let(:api_key) { 'test_api_key' }
  let(:units) { 'metric' }

  before do
      allow(ENV).to receive(:fetch).with('OPENWEATHER_API_KEY', 'test_api_key').and_return(api_key)
  end

  describe '.call' do
    context 'with valid parameters' do
      let(:weather_response) do
        {
          'main' => { 'temp' => 20, 'humidity' => 65 },
          'weather' => [{ 'main' => 'Clear', 'description' => 'clear sky' }]
        }
      end
      let(:forecast_response) do
        {
          'list' => [
            {
              'dt' => Time.now.to_i,
              'main' => { 'temp' => 22, 'temp_min' => 18, 'temp_max' => 25 },
              'weather' => [{ 'main' => 'Clear', 'description' => 'clear sky' }]
            }
          ]
        }
      end

      before do
        stub_request(:any, %r{https://api.openweathermap.org/data/2.5/weather.*})
          .to_return(status: 200, body: weather_response.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:any, %r{https://api.openweathermap.org/data/2.5/forecast.*})
          .to_return(status: 200, body: forecast_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns successful service result with weather data' do
        result = described_class.call(lat: valid_lat, lon: valid_lon, units: units)
        expect(result).to be_success
        expect(result.data).to include(:current, :today, :next_days)
      end
    end

    context 'with invalid parameters' do
      it 'returns error for invalid latitude' do
        result = described_class.call(lat: 91, lon: valid_lon)
        expect(result).to be_error
        expect(result.error).to match(/Latitude/)
      end

      it 'returns error for invalid longitude' do
        result = described_class.call(lat: valid_lat, lon: 181)
        expect(result).to be_error
        expect(result.error).to match(/Longitude/)
      end

      it 'returns error for invalid units' do
        result = described_class.call(lat: valid_lat, lon: valid_lon, units: 'invalid')
        expect(result).to be_error
        expect(result.error).to match(/Invalid units/)
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:any, /.*#{WEATHER_ENDPOINTS[:weather]}.*/)
          .with(query: hash_including({}))
          .to_return(status: 400, body: { message: 'Bad Request' }.to_json)
      end

      it 'returns error result' do
        result = described_class.call(lat: valid_lat, lon: valid_lon)
        expect(result).to be_error
        expect(result.error).to match(/Weather service error/)
      end
    end
  end
end