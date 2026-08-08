class CartsController < ApplicationController
  def show
    @cart = current_cart
    @cart_items = @cart.cart_items.includes(:coffee).to_a
    Coffee.preload_sold_counts(@cart_items.map(&:coffee))
  end
end
