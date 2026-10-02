namespace :study do
  desc "Create the (single) user: bin/rails study:create_user EMAIL=you@example.com PASSWORD=..."
  task create_user: :environment do
    email, password = ENV.values_at("EMAIL", "PASSWORD")
    abort "Usage: bin/rails study:create_user EMAIL=you@example.com PASSWORD=..." if email.blank? || password.blank?
    abort "A user already exists." if User.exists?

    User.create!(email_address: email, password: password)
    puts "Created #{email}"
  end
end
