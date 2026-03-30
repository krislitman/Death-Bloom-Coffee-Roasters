class AdminConstraint
  def matches?(request)
    user_id = request.session.dig("warden.user.user.key", 0, 0)
    return false unless user_id

    User.find_by(id: user_id)&.admin?
  end
end
