class ApplicationMailer < ActionMailer::Base
  default from:     ENV.fetch("MAIL_FROM", "deathbloomcoffeeroasters@proton.me"),
          reply_to: ENV.fetch("SUPPORT_EMAIL", "deathbloomcoffeeroasters@proton.me")
  layout "mailer"
end
