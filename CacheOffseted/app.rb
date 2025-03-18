# frozen_string_literal: true

# Mock Rails cache
module Rails
  module Cache
    @store = {}

    def self.write(key, value)
      @store[key] = value
    end

    def self.read(key)
      @store[key]
    end

    def self.clear
      @store = {}
    end
  end

  def self.cache
    Cache
  end
end

module Cache
  def self.offseted(cache_key:, offset:, limit:)
    cached_data = Rails.cache.read(cache_key)

    return cached_data[:data][offset, limit] if cached_data && cached_data[:size] >= (offset + limit)

    uncached_result = yield if block_given?

    if uncached_result.is_a?(Array)
      updated_data = cached_data ? cached_data[:data] : []
      missing_data = uncached_result - updated_data

      if missing_data.any?
        updated_data.concat(missing_data)
        new_size = updated_data.size

        Rails.cache.write(cache_key, { data: updated_data, size: new_size })
      end
    end

    # Return the requested slice
    Rails.cache.read(cache_key)[:data][offset, limit]
  end
end
