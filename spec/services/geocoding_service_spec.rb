require 'rails_helper'

RSpec.describe GeocodingService do
  let(:valid_address) { '10001' }
  let(:nominatim_response) do
    [{
      'lat' => '40.7506',
      'lon' => '-73.9971',
      'display_name' => 'New York, NY 10001, USA',
      'address' => {
        'postcode' => '10001',
        'city' => 'New York',
        'state' => 'New York'
      }
    }]
  end

  describe '.call' do
    context 'with valid address' do
      before do
        stub_request(:any, "https://nominatim.openstreetmap.org/search")
          .with(
            query: hash_including({
              q: valid_address,
              format: 'json',
              addressdetails: 1,
              limit: 1
            }),
            headers: { 'User-Agent' => described_class::USER_AGENT }
          )
          .to_return(status: 200, body: nominatim_response.to_json)
      end

      it 'returns successful service result with location data' do
        result = described_class.call(valid_address)
        expect(result).to be_success
        expect(result.data).to include(
          lat: 40.7506,
          lon: -73.9971,
          display_name: 'New York, NY 10001, USA',
          zip: '10001'
        )
      end
    end

    context 'with empty address' do
      it 'returns error for blank address' do
        result = described_class.call('')
        expect(result).to be_error
        expect(result.error).to eq('Address is required')
      end

      it 'returns error for nil address' do
        result = described_class.call(nil)
        expect(result).to be_error
        expect(result.error).to eq('Address is required')
      end
    end

    context 'when API returns no results' do
      before do
        stub_request(:any, "https://nominatim.openstreetmap.org/search")
          .with(query: hash_including({}))
          .to_return(status: 200, body: '[]')
      end

      it 'returns error for no results found' do
        result = described_class.call('invalid_address_123')
        expect(result).to be_error
        expect(result.error).to match(/No results found/)
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:any, "https://nominatim.openstreetmap.org/search")
          .with(query: hash_including({}))
          .to_return(status: 400, body: { error: 'Bad Request' }.to_json)
      end

      it 'returns error result' do
        result = described_class.call(valid_address)
        expect(result).to be_error
        expect(result.error).to match(/API error/)
      end
    end

    context 'with different postal code formats' do
      it 'recognizes US ZIP codes' do
        expect(GeocodingService::POSTAL_PATTERNS[:us].match?('12345')).to be true
        expect(GeocodingService::POSTAL_PATTERNS[:us].match?('12345-6789')).to be true
      end

      it 'recognizes Indian PIN codes' do
        expect(GeocodingService::POSTAL_PATTERNS[:india].match?('110001')).to be true
      end

      it 'recognizes generic postal codes' do
        expect(GeocodingService::POSTAL_PATTERNS[:generic].match?('ABC 123')).to be true
        expect(GeocodingService::POSTAL_PATTERNS[:generic].match?('SW1A 1AA')).to be true
      end
    end
  end
end