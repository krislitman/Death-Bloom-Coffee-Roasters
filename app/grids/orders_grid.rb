class OrdersGrid
  include Datagrid

  scope { Order.includes(:order_items) }

  filter(:order_number, :string, header: "Order #") do |value, scope|
    scope.where("order_number ILIKE ?", "%#{value}%")
  end
  filter(:status, :enum, select: Order.statuses.keys.map { |s| [s.humanize, s] }, header: "Status")

  column(:order_number, header: "Order #") do |order|
    order.order_number
  end
  column(:status, header: "Status") { |o| o.status.humanize }
  column(:total, header: "Total") { |o| "$#{'%.2f' % o.total}" }
  column(:items, header: "Items") { |o| o.order_items.sum(:quantity) }
  column(:placed_on, header: "Placed On") { |o| o.created_at.strftime("%b %-d, %Y") }
  column(:actions, header: "") do |order|
    order
  end
end
