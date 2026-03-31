class CartItemsController < ApplicationController
  before_action :set_cart
  before_action :set_cart_item, only: [:update, :destroy]

  def create
    coffee = Coffee.find(cart_item_params[:coffee_id])
    existing = @cart.cart_items.find_by(coffee: coffee)

    if existing
      new_qty = [existing.quantity + cart_item_params[:quantity].to_i, 10].min
      existing.update!(quantity: new_qty)
      @cart_item = existing
    else
      @cart_item = @cart.cart_items.create!(
        coffee: coffee,
        quantity: [cart_item_params[:quantity].to_i, 10].min
      )
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path }
    end
  end

  def update
    new_qty = cart_item_params[:quantity].to_i
    if @cart_item.update(quantity: new_qty)
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
