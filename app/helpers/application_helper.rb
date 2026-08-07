module ApplicationHelper
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "deathbloomcoffeeroasters@proton.me")
  end
end
