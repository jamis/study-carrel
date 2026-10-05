namespace :study_carrel do
  desc "Create the (single) user: bin/rails study_carrel:create_user EMAIL=you@example.com PASSWORD=..."
  task create_user: :environment do
    email, password = ENV.values_at("EMAIL", "PASSWORD")
    abort "Usage: bin/rails study_carrel:create_user EMAIL=you@example.com PASSWORD=..." if email.blank? || password.blank?
    abort "A user already exists." if User.exists?

    User.create!(email_address: email, password: password)
    puts "Created #{email}"
  end
end

namespace :study_carrel do
  desc "Load (or reload) the bundled texts from db/texts/*.txt"
  task load_texts: :environment do
    TextLoader.load_all.each { |w| puts "Loaded #{w.name}: #{w.sections.count} section(s)" }
  end

  desc "Rebuild the full-text search index from the loaded texts"
  task reindex: :environment do
    Unit.reindex_search
    puts "Indexed #{Unit.count} units."
  end
end

namespace :study_carrel do
  desc "Make a user an admin (they can create invitations): bin/rails study_carrel:make_admin EMAIL=you@example.com"
  task make_admin: :environment do
    email = ENV["EMAIL"]
    abort "Usage: bin/rails study_carrel:make_admin EMAIL=you@example.com" if email.blank?

    user = User.find_by(email_address: email.strip.downcase) or abort "No user with that email address."
    user.update!(admin: true)
    puts "#{user.email_address} is an admin."
  end
end
