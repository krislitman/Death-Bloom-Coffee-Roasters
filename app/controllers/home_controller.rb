class HomeController < ApplicationController
  def index
    @featured_coffees = Coffee.active.ordered.limit(4)
  end
end
