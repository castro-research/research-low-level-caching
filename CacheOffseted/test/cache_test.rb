# frozen_string_literal: true

require "minitest/autorun"
require_relative "../app"

CACHE_KEY = "/items/go-pro-12"

class CacheOffsetTest < Minitest::Test
  def setup
    Rails.cache.clear
  end

  def test_returns_cached_data_when_available
    Rails.cache.write(CACHE_KEY, { data: ["picture1", "picture2", "picture3", "picture4"], size: 4 })

    result = Cache.offseted(cache_key: CACHE_KEY, offset: 1, limit: 2)
    assert_equal ["picture2", "picture3"], result
  end

  def test_fetches_and_appends_new_data
    Rails.cache.write(CACHE_KEY, { data: ["picture1", "picture2"], size: 2 })
    
    result = Cache.offseted(cache_key: CACHE_KEY, offset: 1, limit: 3) do
      ["picture3", "picture4"]
    end

    assert_equal ["picture2", "picture3", "picture4"], result
    assert_equal ["picture1", "picture2", "picture3", "picture4"], Rails.cache.read(CACHE_KEY)[:data]
  end

  def test_does_not_duplicate_existing_pictures
    Rails.cache.write(CACHE_KEY, { data: ["picture1", "picture2"], size: 2 })
    
    result = Cache.offseted(cache_key: CACHE_KEY, offset: 0, limit: 4) do
      ["picture1", "picture2", "picture3", "picture4"]
    end

    assert_equal ["picture1", "picture2", "picture3", "picture4"], result
    assert_equal ["picture1", "picture2", "picture3", "picture4"], Rails.cache.read(CACHE_KEY)[:data]
  end

  def test_handles_cache_miss_properly
    result = Cache.offseted(cache_key: CACHE_KEY, offset: 0, limit: 2) do
      ["picture5", "picture6"]
    end

    assert_equal ["picture5", "picture6"], result
    assert_equal ["picture5", "picture6"], Rails.cache.read(CACHE_KEY)[:data]
  end

  def test_fetches_more_pictures_if_needed
    Rails.cache.write(CACHE_KEY, { data: ["picture1", "picture2", "picture3"], size: 3 })

    result = Cache.offseted(cache_key: CACHE_KEY, offset: 2, limit: 3) do
      ["picture4", "picture5"]
    end

    assert_equal ["picture3", "picture4", "picture5"], result
    assert_equal ["picture1", "picture2", "picture3", "picture4", "picture5"], Rails.cache.read(CACHE_KEY)[:data]
  end
end
