class CheckoutsController < ApplicationController
  before_action :load_cart

  def create
    if @cart.nil? || @cart.item_count.zero?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    session = StripeCheckoutService.new(cart: @cart, user: current_user).call
    redirect_to session.url, allow_other_host: true
  rescue StandardError => e
    Rails.logger.error "Checkout create error: #{e.class}: #{e.message}"
    redirect_to cart_path, alert: "Something went wrong. Please try again."
  end

  def success
  end

  def cancel
  end

  private

  def load_cart
    @cart = current_cart
  end
end
