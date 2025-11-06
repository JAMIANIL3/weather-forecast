# frozen_string_literal: true

module Api
  class Config
    class << self
      def openweather
        {
          api_key: credentials.openweather_api_key,
          units: "metric"
        }
      end

      def nominatim
        {
          user_agent: "rails-weather-demo/#{Rails.application.config.version}"
        }
      end

      private

      def credentials
        Rails.application.credentials
      end
    end
  end
end