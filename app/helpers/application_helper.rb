module ApplicationHelper
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "hello@deathbloomcoffee.com")
  end
end
