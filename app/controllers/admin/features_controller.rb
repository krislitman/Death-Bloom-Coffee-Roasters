class Admin::FeaturesController < Admin::BaseController
  def index
    @features = Flipper.features.sort_by(&:key)
  end

  def update
    @feature = Flipper.feature(params[:id])

    if params[:enabled] == "true"
      @feature.enable
    else
      @feature.disable
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_features_path }
    end
  end
end
