class CoffeesController < ApplicationController
  def index
    @coffees = Coffee.active.ordered
    @coffees = @coffees.where(roast_level: params[:roast_level]) if params[:roast_level].present?
  end

  def show
    @coffee = Coffee.active.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
