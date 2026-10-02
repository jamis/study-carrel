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
end
