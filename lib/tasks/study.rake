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

namespace :study do
  desc "Load (or reload) the bundled texts from db/texts/*.txt"
  task load_texts: :environment do
    TextLoader.load_all.each { |w| puts "Loaded #{w.name}: #{w.sections.count} section(s)" }
  end
end
