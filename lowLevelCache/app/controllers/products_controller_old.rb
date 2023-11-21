class ProductsController < ApplicationController
    include ProductsHelper
    MEMORY = ActiveSupport::Cache::MemoryStore.new

    def index
      @products = Rails.cache.fetch('products', expires_in: 10.minutes) do
        # Fake database call to get all products
        # This method will call the Star Wars API and return all people
        fake_get_from_db
      end

      # return the products array
      render json: @products
    end

    def details
      @product = MEMORY.fetch("product/#{params[:id]}/details", expires_in: 10.minutes) do
        fake_show_from_db(params[:id])
      end

      render json: @product
    end

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
end
