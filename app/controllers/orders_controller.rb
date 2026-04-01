class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @grid = OrdersGrid.new(params[:orders_grid] || {}) do |scope|
      scope.where(user: current_user).order(created_at: :desc)
    end
  end

  def show
    @order = current_user.orders.find(params[:id])
    @order_items = @order.order_items.includes(:coffee)
  end
end
