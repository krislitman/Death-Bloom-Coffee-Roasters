class OrderLookupsController < ApplicationController
  def new
  end

  def create
    order = Order.find_by(order_number: normalized_order_number)

    if order && order.email.present? && order.email.casecmp?(params[:email].to_s.strip)
      @order = order
      @order_items = order.order_items.includes(:coffee)
      render :show
    else
      flash.now[:alert] = "We couldn't find an order matching that number and email."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def normalized_order_number
    params[:order_number].to_s.strip.upcase
  end
end
