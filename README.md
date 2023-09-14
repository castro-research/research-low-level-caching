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

# Example with Rails

First we can try it in terminal with rails console

```bash
$ rails c
```

Then we can try it with a simple example

```bash
Loading development environment (Rails 7.0.8)
3.0.0 :001 > age = 27
 => 27
3.0.0 :002 > Rails.cache.write("alekinho", age)
 => true
3.0.0 :003 > Rails.cache.read("alekinho")
 => nil
``` 

What the heck happen here ? Well, we need to set up the cache store, in this case we are going to use the memory store, but you can use redis, memcached, etc.

```bash
  lowLevelCache git:(main) ✗ rails c
Loading development environment (Rails 7.0.8)
3.0.0 :001 > Rails.cache.class
 => ActiveSupport::Cache::NullStore 
3.0.0 :002 > Rails.cache = ActiveSupport::Cache::MemoryStore.new
 => #<ActiveSupport::Cache::MemoryStore entries=0, size=0, options={:compress=>false, :compress_threshold=>1024}> 
3.0.0 :003 > Rails.cache.class
 => ActiveSupport::Cache::MemoryStore 
3.0.0 :004 > age = 27
 => 27 
3.0.0 :005 > Rails.cache.write("alekinho", age)
 => true 
3.0.0 :006 > Rails.cache.read("alekinho")
 => 27 
```

We also can check the config/development.rb file and see the cache store

```ruby
  config.cache_store = :memory_store, { size: 64.megabytes }
```

But not that by default, Rails check the existence of file called: `caching-dev.txt``

```ruby
if Rails.root.join("tmp/caching-dev.txt").exist?
```

So we can create that file and check again

```bash
➜  lowLevelCache git:(main) ✗ touch tmp/caching-dev.txt
➜  lowLevelCache git:(main) ✗ rails c
Loading development environment (Rails 7.0.8)
3.0.0 :001 > age = 27
 => 27 
3.0.0 :002 > Rails.cache.write("alekinho", age)
 => true 
3.0.0 :003 > Rails.cache.read("alekinho")
 => 27 
```

We saw how write/read works, what about fetch ?

fetch provides a nice wrapper around reading and writing. You pass it a key and a block, and if a value is present for that key in the cache it will be returned and the block is not executed. If there is no cached value for that key (or it has expired, more on expiration later) it will execute the block and store the result in the cache for next time.

```bash
3.0.0 :004 > Rails.cache.fetch("alekinho") { 27 }
 => 27
```

We can also pass a time to expire the cache

```bash
3.0.0 :005 > Rails.cache.fetch("alekinho", expires_in: 1.minute) { 30 }
 => 27
```

after 1 minute

```bash
3.0.0 :006 > Rails.cache.fetch("alekinho", expires_in: 1.minute) { 30 }
 => 30
```

## When to Use Low-Level Caching

WIP


# References

https://guides.rubyonrails.org/caching_with_rails.html

https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

https://reinteractive.com/articles/rails-low-level-caching-tips

https://www.honeybadger.io/blog/rails-low-level-caching/
