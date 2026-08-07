class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [:show, :update]

  def index
    @orders = Order.includes(:order_items).order(created_at: :desc)
  end

  def show
    @order_items = @order.order_items.includes(:coffee)
  end

  def update
    if @order.update(order_params)
      redirect_to admin_order_path(@order), notice: "Order ##{@order.order_number} updated."
    else
      @order_items = @order.order_items.includes(:coffee)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status, :carrier, :tracking_number)
  end
end
