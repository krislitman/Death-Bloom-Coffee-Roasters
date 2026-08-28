module ApplicationHelper
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "deathbloomcoffeeroasters@proton.me")
  end

  def cart_drawer_items
    items = current_cart.cart_items.includes(:coffee).to_a
    Coffee.preload_sold_counts(items.map(&:coffee))
    items
  end
end
