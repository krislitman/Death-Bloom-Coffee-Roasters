module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      payload    = request.raw_post
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV.fetch("STRIPE_WEBHOOK_SECRET")
      )

      case event.type
      when "checkout.session.completed"
        OrderFulfillmentService.new(checkout_session: event.data.object).call
      end

      head :ok
    rescue Stripe::SignatureVerificationError
      head :bad_request
    rescue StandardError => e
      Rails.logger.error "Stripe webhook error: #{e.class}: #{e.message}"
      head :internal_server_error
    end
  end
end
