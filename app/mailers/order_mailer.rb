class OrderMailer < ApplicationMailer
  default from:     ENV.fetch("MAIL_FROM", "orders@deathbloomcoffeeroasters.com"),
          reply_to: ENV.fetch("SUPPORT_EMAIL", "deathbloomcoffeeroasters@proton.me")

  def confirmation(order)
    @order = order
    mail(to: @order.email, subject: "Your Death Bloom order #{@order.order_number} is confirmed")
  end
end
