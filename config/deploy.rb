lock "~> 3.20"

set :application, "study_carrel"
set :repo_url, "https://github.com/jamis/study-carrel.git" # public, so the server can clone over HTTPS
set :branch, "master"
set :deploy_to, "/home/deploy/study_carrel"
set :keep_releases, 5

# The droplet has ~450 MB of RAM: compile native gems one at a time.
set :bundle_jobs, 1

# The SQLite databases and logs live in shared/, so they survive deploys.
append :linked_dirs, "storage", "log", "tmp/pids"
append :linked_files, "config/master.key"

# Non-interactive SSH sessions don't load the shell profile; put mise and its shims on the PATH
# so `bundle` and `rake` resolve to the Ruby in .ruby-version.
set :default_env, { "PATH" => "/home/deploy/.local/bin:/home/deploy/.local/share/mise/shims:$PATH" }

namespace :deploy do
  desc "Restart Puma (systemd) and wait for it to answer /up"
  task :restart do
    on roles(:app) do
      execute :sudo, "systemctl", "restart", "study_carrel"
      execute :curl, "-fsS", "-o", "/dev/null", "--retry", "15", "--retry-delay", "1", "--retry-connrefused",
              "http://127.0.0.1:3000/up"
    end
  end

  after :publishing, :restart
  after :reverted, :restart
end
