# Development only: a throwaway local login. In production, use `bin/rails study_carrel:create_user`.
if Rails.env.development? && !User.exists?
  User.create!(email_address: "dev@example.com", password: "password")
end

TextLoader.load_all
