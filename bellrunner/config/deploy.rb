require 'capistrano_colors'
require "rvm/capistrano" # Rvm bootstrap
require 'bundler/capistrano'
require 'capistrano/ext/multistage'

default_run_options[:pty] = true

set :stages, [ :staging, :production]
set :default_stage, :staging

set :repository,  "git@github.com:jacobpatton/bellrunner-devmen.git"
set :scm, :git
set :deploy_via,  :remote_cache
set :keep_releases, 5

set :user, "devmen"

set :use_sudo, false

set :rvm_ruby_string, "1.9.3@bellrunner-devmen"
set :rvm_type, :user
set :normalize_asset_timestamps, false


after  "deploy",                 "deploy:cleanup"
after  "deploy:finalize_update", "deploy:config"
after  "deploy:create_symlink",  "deploy:migrate"


namespace :deploy do

  task :config do
    %w(database).each do |file|
      run "cd #{release_path}/config && ln -nfs #{shared_path}/config/#{file}.yml #{release_path}/config/#{file}.yml"
    end

  end


end
