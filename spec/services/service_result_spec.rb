require 'rails_helper'

RSpec.describe ServiceResult do
  describe '.success' do
    let(:data) { { key: 'value' } }
    let(:result) { described_class.success(data) }

    it 'creates a successful result' do
      expect(result).to be_success
      expect(result).not_to be_error
      expect(result.data).to eq(data)
      expect(result.error).to be_nil
    end
  end

  describe '.error' do
    let(:error_message) { 'Something went wrong' }
    let(:result) { described_class.error(error_message) }

    it 'creates an error result' do
      expect(result).to be_error
      expect(result).not_to be_success
      expect(result.error).to eq(error_message)
      expect(result.data).to be_nil
    end
  end

  describe '#success?' do
    it 'returns true for success results' do
      result = described_class.success('data')
      expect(result.success?).to be true
    end

    it 'returns false for error results' do
      result = described_class.error('error')
      expect(result.success?).to be false
    end
  end

  describe '#error?' do
    it 'returns true for error results' do
      result = described_class.error('error')
      expect(result.error?).to be true
    end

    it 'returns false for success results' do
      result = described_class.success('data')
      expect(result.error?).to be false
    end
  end
end