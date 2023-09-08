# Introduction

Sometimes you need to cache a particular value or query result instead of caching view fragments. Rails' caching mechanism works great for storing any serializable information.

The most efficient way to implement low-level caching is using the Rails.cache.fetch method. This method does both reading and writing to the cache. When passed only a single argument, the key is fetched and value from the cache is returned. If a block is passed, that block will be executed in the event of a cache miss. The return value of the block will be written to the cache under the given cache key, and that return value will be returned. In case of cache hit, the cached value will be returned without executing the block.

# Motivation

This is part of Flecto Educa, and we want to share our knowledge with the community and help other developers to improve their skills.

# Technologies used

- Ruby
- Rails
- NodeJS
- Fastify

# References

https://guides.rubyonrails.org/caching_with_rails.html

https://reinteractive.com/articles/rails-low-level-caching-tips

