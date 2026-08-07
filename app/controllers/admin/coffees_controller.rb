class Admin::CoffeesController < Admin::BaseController
  before_action :set_coffee, only: [:edit, :update, :destroy]

  def index
    @coffees = Coffee.ordered
  end

  def new
    @coffee = Coffee.new
  end

  def create
    @coffee = Coffee.new(coffee_params)

    if @coffee.save
      redirect_to admin_coffees_path, notice: "#{@coffee.name} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @coffee.update(coffee_params)
      redirect_to admin_coffees_path, notice: "#{@coffee.name} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coffee.destroy
    redirect_to admin_coffees_path, notice: "#{@coffee.name} deleted."
  end

  private

  def set_coffee
    @coffee = Coffee.find_by!(slug: params[:id])
  end

  def coffee_params
    params.require(:coffee).permit(
      :name, :origin, :roast_level, :processing, :price, :description,
      :active, :position, tasting_note_ids: []
    )
  end
end
