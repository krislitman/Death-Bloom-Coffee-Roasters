class CoffeesController < ApplicationController
  def index
    @coffees = Coffee.active.ordered
    @coffees = @coffees.where(roast_level: params[:roast_level]) if params[:roast_level].present?
    @coffees = @coffees.to_a
    Coffee.preload_sold_counts(@coffees)
  end

  def show
    @coffee = Coffee.active.find_by!(slug: params[:slug])
  end
end
