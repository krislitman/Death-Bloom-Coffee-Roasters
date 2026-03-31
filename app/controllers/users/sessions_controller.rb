class Users::SessionsController < Devise::SessionsController
  private

  def after_sign_in_path_for(resource)
    merge_guest_cart_into_user_cart
    super
  end

  def merge_guest_cart_into_user_cart
    guest_token = session[:cart_token]
    return unless guest_token

    guest_cart = Cart.find_by(session_token: guest_token, user: nil)
    return unless guest_cart

    user_cart = Cart.current_for(user: current_user)
    user_cart.merge_guest_cart(guest_cart)

    session.delete(:cart_token)
  end
end
