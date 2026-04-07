class NewsletterSubscriptionsController < ApplicationController
  def create
    @subscription = NewsletterSubscription.new(email: params[:email])

    respond_to do |format|
      if @subscription.save
        format.turbo_stream
        format.html { redirect_to root_path, notice: "You're subscribed!" }
      else
        @error = @subscription.errors.full_messages.first
        format.turbo_stream { render :error }
        format.html { redirect_to root_path, alert: @error }
      end
    end
  end
end
