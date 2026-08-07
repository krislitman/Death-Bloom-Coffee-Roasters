module ApplicationHelper
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "hello@deathbloomcoffeeroasters.com")
  end
end
