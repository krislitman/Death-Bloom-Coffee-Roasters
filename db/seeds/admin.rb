email, password =
  if Rails.env.production?
    [ ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"] ]
  else
    [ "admin@dev.com", "admindev123" ]
  end

if email.present? && password.present?
  admin = User.find_or_initialize_by(email: email)

  if admin.new_record?
    admin.password              = password
    admin.password_confirmation = password
  end

  admin.role = :admin
  admin.save!

  puts "Admin user seeded: #{admin.email}"
else
  puts "Admin user skipped — set ADMIN_EMAIL and ADMIN_PASSWORD to seed one."
end
