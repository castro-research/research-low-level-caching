class ProductsController < ApplicationController
  include ProductsHelper

  def index
    puts "Hi, I'm the index action"
    # return the products array
    render json: @products
  end

  def details
    puts "Hi, I'm the details action"

    render json: @product
  end

  def show
    puts "Hi, I'm the product show action"

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
