class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_cart

  private

  def current_cart
    @current_cart ||= Cart.current_for(
      user: current_user,
      session_token: guest_session_token
    )
  end

  def guest_session_token
    session[:cart_token] ||= SecureRandom.hex(16)
  end
end
