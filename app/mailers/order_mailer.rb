class OrderMailer < ApplicationMailer
  default from: ENV.fetch("SUPPORT_EMAIL", "hello@deathbloomcoffee.com")

  def confirmation(order)
    @order = order
    mail(to: @order.email, subject: "Your Death Bloom order #{@order.order_number} is confirmed")
  end
end
