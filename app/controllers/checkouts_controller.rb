class CheckoutsController < ApplicationController
  before_action :load_cart, only: :create

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
    @order = reconcile_order(params[:session_id])
  end

  def cancel
  end

  private

  def load_cart
    @cart = current_cart
  end

  def reconcile_order(session_id)
    return if session_id.blank?

    order = Order.find_by(stripe_checkout_session_id: session_id)
    return order if order

    session = Stripe::Checkout::Session.retrieve(
      id: session_id, expand: [ "customer_details", "collected_information" ]
    )
    return unless session.payment_status == "paid"

    OrderFulfillmentService.new(checkout_session: session).call
    Order.find_by(stripe_checkout_session_id: session_id)
  rescue Stripe::StripeError => e
    Rails.logger.error "Checkout success reconcile error: #{e.class}: #{e.message}"
    nil
  end
end
