class ProductsController < ApplicationController
  include ProductsHelper

  def index
    puts "Hi, I'm the index action"
    @products = fake_get_from_db
    # return the products array
    render json: @products
  end

  def details
    puts "Hi, I'm the details action"
    @product = fake_show_from_db(params[:id])
    render json: @product
  end

  def show
    puts "Hi, I'm the product show action"
    @product = fake_show_from_db(params[:id])
    render json: @product
  end

  def update
    render json: @product
  end
end
