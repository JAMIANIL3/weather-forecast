require 'rails_helper'

RSpec.shared_examples 'http_client' do
  let(:test_url) { 'https://api.example.com/test' }
  let(:test_params) { { key: 'value' } }
  let(:test_headers) { { 'Content-Type' => 'application/json' } }
  let(:test_response) { { 'data' => 'test' } }

  describe '#get_json' do
    context 'with successful response' do
      before do
        stub_request(:get, test_url)
          .with(query: test_params, headers: test_headers)
          .to_return(status: 200, body: test_response.to_json)
      end

      it 'makes a GET request and returns parsed JSON' do
        response = subject.send(:get_json, test_url, query: test_params, headers: test_headers)
        expect(response).to eq(test_response)
      end
    end

    context 'with error response' do
      before do
        stub_request(:get, test_url)
          .to_return(status: 400, body: { error: 'Bad Request' }.to_json)
      end

      it 'raises ApiError for non-200 response' do
        expect {
          subject.send(:get_json, test_url)
        }.to raise_error(ApiError)
      end
    end

    context 'with invalid JSON response' do
      before do
        stub_request(:get, test_url)
          .to_return(status: 200, body: 'invalid json')
      end

      it 'raises ApiError for invalid JSON' do
        expect {
          subject.send(:get_json, test_url)
        }.to raise_error(ApiError)
      end
    end

    context 'with network error' do
      before do
        stub_request(:get, test_url)
          .to_raise(HTTParty::Error)
      end

      it 'raises ApiError for network errors' do
        expect {
          subject.send(:get_json, test_url)
        }.to raise_error(ApiError)
      end
    end
  end
end