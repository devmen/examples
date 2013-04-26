server "78.47.61.228", :app, :web, :db, :primary => true

set :shared_host, "78.47.61.228"
#set :bundle_cmd, ". ~/.bash_login; . ~/.bashrc; . ~/.rvmrc && bundle"
set :branch, "master"
set :application, "bellrunner-devmen"
set :unicorn_env, "staging"
set :deploy_to,   "/home/devmen/apps/bellrunner-devmen/"
set :rails_env, "staging"
#require 'capistrano-unicorn'

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
end
