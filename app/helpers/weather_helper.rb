module WeatherHelper
  def cache_status_message(cache_key, from_cache)
    return "Updated just now" unless from_cache

    entry = Rails.cache.read_entry(cache_key)
    if entry&.expires_at
      minutes_left = ((entry.expires_at - Time.current) / 60).round
      "Refreshes in #{minutes_left} minute#{'s' if minutes_left != 1}"
    else
      "Refreshes soon"
    end
  rescue
    "Refreshes soon"
  end
end
