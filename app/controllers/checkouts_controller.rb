class CheckoutsController < ApplicationController
  before_action :load_cart

  def show
    redirect_to cart_path, alert: "Your cart is empty." if @cart.item_count.zero?
  end

  def rates
    destination = destination_params.to_h.symbolize_keys
    rates = ShippoRateService.new(cart: @cart, destination: destination).call
    session[:shippo_rates] = rates.map { |r| r.transform_keys(&:to_s) }
    render partial: "checkouts/rates", locals: { rates: rates, destination: destination_params }
  rescue ShippoRateService::Error => e
    Rails.logger.error "ShippoRateService error: #{e.message}"
    render partial: "checkouts/rates_error", status: :unprocessable_entity
  end

  def create
    rate = validated_rate
    unless rate
      redirect_to checkout_path, alert: "Please select a valid shipping rate." and return
    end

    unless valid_email?(checkout_params[:email])
      redirect_to checkout_path, alert: "Please enter a valid email address." and return
    end

    pending_checkout = PendingCheckout.create!(
      cart:                        @cart,
      email:                       checkout_params[:email],
      shipping_address_name:       checkout_params[:name],
      shipping_address_line1:      checkout_params[:line1],
      shipping_address_line2:      checkout_params[:line2],
      shipping_address_city:       checkout_params[:city],
      shipping_address_state:      checkout_params[:state],
      shipping_address_zip:        checkout_params[:zip],
      shipping_address_country:    checkout_params[:country].presence || "US",
      shippo_rate_id:              rate["id"],
      shippo_rate_amount_cents:    rate["amount_cents"],
      shippo_rate_carrier:         rate["carrier"],
      shippo_rate_service:         rate["service"]
    )

    stripe_session = StripeCheckoutService.new(
      cart:             @cart,
      pending_checkout: pending_checkout,
      user:             current_user
    ).call

    redirect_to stripe_session.url, allow_other_host: true
  rescue StandardError => e
    Rails.logger.error "Checkout create error: #{e.class}: #{e.message}"
    redirect_to checkout_path, alert: "Something went wrong. Please try again."
  end

  def success
  end

  def cancel
  end

  private

  def load_cart
    @cart = current_cart
  end

  def checkout_params
    params.require(:checkout).permit(:email, :name, :line1, :line2, :city, :state, :zip, :country, :rate_id)
  end

  def destination_params
    params.require(:destination).permit(:name, :line1, :line2, :city, :state, :zip, :country)
  end

  def validated_rate
    valid_rates = session[:shippo_rates] || []
    valid_rates.find { |r| r["id"] == checkout_params[:rate_id] }
  end

  def valid_email?(email)
    email.present? && URI::MailTo::EMAIL_REGEXP.match?(email)
  end
end
