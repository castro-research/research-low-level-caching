# Introduction

Sometimes you need to cache a particular value or query result instead of caching view fragments. Rails' caching mechanism works great for storing any serializable information.

The most efficient way to implement low-level caching is using the Rails.cache.fetch method. This method does both reading and writing to the cache. When passed only a single argument, the key is fetched and value from the cache is returned. If a block is passed, that block will be executed in the event of a cache miss. The return value of the block will be written to the cache under the given cache key, and that return value will be returned. In case of cache hit, the cached value will be returned without executing the block.

# Motivation

This is part of Flecto Educa, and we want to share our knowledge with the community and help other developers to improve their skills.

# Technologies used

- Ruby
- Rails
- Redis
- rest-client
- hiredis
- Docker

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

A great use case for this kind of caching is when you are hitting an external API to get a value that may not change that often. In one client app we had some calculations based on the current futures price of some commodities. Rather than hit the API on every page refresh, we cache the value for a period of time (in our case 10 minutes).

imagine you have some API that returns /products and /products/:id, but you don't change the products that often, so you can cache the result of /products and /products/:id for 10 minutes.

For example, in `lowLevelCache` folder, i had created a Product Controller + Product Helper.

First, let me show you the code of the controller in `lowLevelCache/app/controllers/products_controller.rb`

I will start calling the ProductHelper that will replace our Model, because i dont want to use a database for this example.

```ruby
class ProductsController < ApplicationController
    include ProductsHelper
end
```

before create helper, let use a simple gem that will help us to make request to an external API

Go to Gemfile and add

```ruby
gem 'rest-client'
```

then run

```bash
bundle install
```

Let's create 2 functions to simulate index and show

```ruby
module ProductsHelper
    def fake_get_from_db
        response = RestClient.get 'https://swapi.dev/api/people'
        JSON.parse(response.body)
    end

    def fake_show_from_db(id)
        response = RestClient.get "https://swapi.dev/api/people/#{id}"
        JSON.parse(response.body)
    end
end
```

Now we can create the index

```ruby
...
    def index
      @products = Rails.cache.fetch('products', expires_in: 10.minutes) do
        # Fake database call to get all products
        # This method will call the Star Wars API and return all people
        fake_get_from_db
      end

      # return the products array
      render json: @products
    end
...
```

As we saw before, we are using fetch to get the products in cache, if the products are not in the cache, we will call the fake_get_from_db method, that will call the Star Wars API and return all people.

Same thing we can do with show

```ruby
  def show
      # Get the product from the cache, or if it doesn't exist, get it from the fake database
      @product = Rails.cache.fetch("product/#{params[:id]}", expires_in: 10.minutes) do
        # Fake database call to get the product
        # This is a call for a single product, so we need to pass the id
        # to the fake_show_from_db method
        # This method will call the Star Wars API and return the person with the id
        fake_show_from_db(params[:id])
      end

      # return the product object
      render json: @product
    end
```

Sorry about the confusion between `people` and `products`, ignore this and focus on the code.

So...

Now, imagine you need to update the "product", but we have cache enabled, so we need to clear the cache.

```ruby
def update
        # Ignore the find and update, because we are not using a database
        # @product = Product.find(params[:id])
        # @product.update(product_params)
        #
        # Remove the cache for the updated product
        Rails.cache.delete("product/#{params[:id]}")

        # Return the updated product
        render json: @product
  end
```

We can also update the cache when we update, but lets update in the next request, just YAGNI.

Now we can start the server:

```bash
cd lowLevelCache
rails s
```

and we can get response time with the `products.sh`

```bash
➜  research-low-level-caching git:(main) ✗ ./products.sh       
The products API take: 3.310715 seconds
The products API take: 0.851138 seconds
```

So, in the second request this is faster, because we are using cache.

```bash
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 0.010398 seconds
The products API take: 0.008920 seconds
```

Remember: This caching that we are using here are in memory, so if you restart the server, the cache will be cleared.

So, how to use Redis ?

# Using Rails.cache.fetch with Redis

To be fast, lets create a `docker-compose.yml` file

now, we can run the command

```bash
docker-compose up -d
```

after install, lets add more one gem

In the first moment, i tried to install redis-rails and redis-store, but i got some errors, so i decided to use the hiredis gem
Official Recommendation: https://guides.rubyonrails.org/caching_with_rails.html#cache-stores

```ruby
# FlectoEduca packages
# for requests
gem 'rest-client'
# for redis usage
gem 'redis', '~> 5.0', '>= 5.0.7'
gem 'hiredis'
```

and run

```bash
bundle install
```

Now, we need to change the `config/environments/development.rb` file

```ruby
    config.cache_store = :redis_cache_store, { url: "redis://localhost:6379/0" }
```

OBS: you can also add a expire time, but read the documentation to understand how it works.
OBS2: links in the references section.

Remember that we check the `tmp/caching-dev.txt`, lets remove this file.

```bash
rm tmp/caching-dev.txt
```

Now, we can start the server

```bash
➜  lowLevelCache git:(main) ✗ rails s        
=> Booting Puma
=> Rails 7.0.8 application starting in development 
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 5.6.7 (ruby 3.0.0-p0) ("Birdie's Version")
*  Min threads: 5
*  Max threads: 5
*  Environment: development
*          PID: 88458
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

and we can get response time with the `products.sh`

```bash
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 3.750448 seconds
The products API take: 1.049783 seconds
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 0.012662 seconds
The products API take: 0.010791 seconds
```

WOW, kinda FASTER !

How do we know that we are using Redis ?

```bash
docker compose exec cache redis-cli
```

show all keys

```bash
127.0.0.1:6379> KEYS *
1) "product/1"
2) "products"
127.0.0.1:6379> 
```

Now, we can stop the server, and run rails again
  
```bash
➜  lowLevelCache git:(main) ✗ rails s
```

And run the `products.sh` again

```bash
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 0.218349 seconds
The products API take: 0.008394 seconds
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 0.021605 seconds
The products API take: 0.008456 seconds
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 0.013654 seconds
The products API take: 0.010118 seconds
➜  research-low-level-caching git:(main) ✗ ./products.sh
The products API take: 0.011347 seconds
The products API take: 0.009350 seconds
```

------

# Memcache and Redis

If you want to use a single API to store in memory, instead redis you can set this in Fetch

first let's create a route for details:

```ruby
  get '/products/:id/details', to: 'products#details'
```

add this on top of class

```ruby
class ProductsController < ApplicationController
 include ProductsHelper
 # add this line
 MEMORY = ActiveSupport::Cache::MemoryStore.new

 .....
```

Now, use the memory store

```ruby
    def details
      @product = MEMORY.fetch("product/#{params[:id]}/details", expires_in: 10.minutes) do
        fake_show_from_db(params[:id])
      end
    end
```

------

# Improvements

Now, we will let the Controller more clean, and cache the whole request, Instead only the response.

This will be useful, because if you change the params of the request, the cache will be different.

Let's remove the hiredis gem

We dont need any gem, since Rails v5 support Built-in Cache

We can see a Redis front of application in lib/http_cache.rb

To use it, lets modify the development.rb and add:

```ruby
require "http_cache"
config.middleware.use HttpCache
```

You can check if is used:

```bash
➜  lowLevelCache git:(feat/rack-middleware-rails) rake middleware
....
use HttpCache
run LowLevelCache::Application.routes
```

Now, all request will be cached on front of app:

```bash

==================================================
Started GET "/products/1" for 127.0.0.1 at 2023-11-20 01:39:38 +0000
==================================================
Request method: GET
Request path: /products/1
Request params: {}
Request headers: []
Cache hit for key: http_cache-GET/products/1{}[]
Started GET "/products/1" for 127.0.0.1 at 2023-11-20 01:39:39 +0000
==================================================
Request method: GET
Request path: /products/1
Request params: {}
Request headers: []
Cache hit for key: http_cache-GET/products/1{}[]
```

--------------------


I also rename current products_controller.rb to products_controller_old.rb

the products_controller.rb will only have the methods.

# References

https://guides.rubyonrails.org/caching_with_rails.html

https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

https://reinteractive.com/articles/rails-low-level-caching-tips

https://www.honeybadger.io/blog/rails-low-level-caching/

# Rails Redis docs

http://redis-store.org/redis-rails

https://github.com/redis-store/redis-rails

https://github.com/rack/rack-cache