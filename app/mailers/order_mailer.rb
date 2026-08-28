class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order = order
    mail(to: @order.email, subject: "Your Death Bloom order #{@order.order_number} is confirmed")
  end
end
