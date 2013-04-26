# ------------------------------------------------------------------------------
# Sample rails 3 config
# ------------------------------------------------------------------------------

# Set your full path to application.
rails_root = File.expand_path('../../../', __FILE__)
app_path = rails_root
shared_path = rails_root

# Set unicorn options
worker_processes 2
preload_app true
timeout 300
listen 3000, :backlog => 2048

# Spawn unicorn master worker for user apps (group: apps)


# Fill path to your app
working_directory app_path

# Should be 'production' by default, otherwise use other env
rails_env = ENV['RAILS_ENV'] || 'development'

# Log everything to one file
stderr_path "#{rails_root}/log/unicorn.stderr.log"
stdout_path "#{rails_root}/log/unicorn.stdout.log"

# Set master PID location
pid "#{rails_root}/tmp/pids/unicorn.pid"

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end
