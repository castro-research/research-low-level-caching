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
    render json: @product
  end
end
