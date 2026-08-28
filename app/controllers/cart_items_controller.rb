class CartItemsController < ApplicationController
  MAX_QUANTITY = 10

  before_action :set_cart
  before_action :set_cart_item, only: [:update, :destroy]

  def create
    coffee = Coffee.find(cart_item_params[:coffee_id])
    existing = @cart.cart_items.find_by(coffee: coffee)
    requested = (existing&.quantity.to_i) + cart_item_params[:quantity].to_i
    allowed = stock_limited(coffee, [requested, MAX_QUANTITY].min).clamp(0, MAX_QUANTITY)

    if allowed.zero?
      flash.now[:alert] = "#{coffee.name} is sold out."
      return respond_with_cart
    end

    flash.now[:alert] = "Only #{allowed} left in stock." if allowed < requested

    if existing
      existing.update!(quantity: allowed)
      @cart_item = existing
    else
      @cart_item = @cart.cart_items.create!(coffee: coffee, quantity: allowed)
    end

    respond_with_cart
  end

  def update
    allowed = stock_limited(@cart_item.coffee, cart_item_params[:quantity].to_i)

    if allowed.positive? && @cart_item.update(quantity: allowed)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to cart_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@cart_item) }
        format.html { redirect_to cart_path }
      end
    end
  end

  def destroy
    @cart_item.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path }
    end
  end

  private

  def respond_with_cart
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path }
    end
  end

  def stock_limited(coffee, quantity)
    return quantity unless Flipper.enabled?(:inventory)

    [quantity, coffee.available_stock].min
  end

  def set_cart
    @cart = current_cart
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end

  def cart_item_params
    params.require(:cart_item).permit(:coffee_id, :quantity)
  end
end
