# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Git as the SCM
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Bundler, plus asset precompile and migrations
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"

# Our own tasks
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
