# Development only: a throwaway local login. In production, use `bin/rails study:create_user`.
if Rails.env.development? && !User.exists?
  User.create!(email_address: "jamis.buck@gmail.com", password: "password")
end
