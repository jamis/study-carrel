namespace :study_carrel do
  desc "Load (or reload) the bundled texts; safe to repeat, never deletes notes"
  task :load_texts do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, "study_carrel:load_texts"
        end
      end
    end
  end

  desc "List the commits on origin/<branch> that haven't been deployed yet"
  task :undeployed do
    deployed = nil
    on roles(:app) do
      deployed = capture(:cat, current_path.join("REVISION")).strip
    end

    run_locally do
      branch = fetch(:branch)
      execute :git, :fetch, "--quiet", "origin", branch
      log = capture(:git, :log, "--format='%h %s (%an, %ar)'", "#{deployed}..origin/#{branch}")
      puts "Deployed: #{deployed[0, 7]}"
      puts log.empty? ? "Nothing new since the last deploy." : log
    end
  end
end
