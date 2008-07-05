role :app, domain
role :web, domain
role :db,  domain, :primary => true

#############################################################
#	Application
#############################################################

set :application, "sonik.nu"
set :deploy_to, "/home/server/#{application}"

#############################################################
#	Settings
#############################################################

default_run_options[:pty] = true
set :use_sudo, true

#############################################################
#	Servers
#############################################################

set :user, “jiku”
set :domain, “sonik.nu”
server domain, :app, :web
role :db, domain, :primary => true

#############################################################
#	Git
#############################################################

set :repository,  "git://github.com/prism/bks.git"
set :scm_username, “prism”
set :scm_password, “megaman”
set :checkout, “export”

#

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

#############################################################
#	Passenger
#############################################################

namespace :passenger do
  desc “Restart Application”
  task :restart do
    run “touch #{current_path}/tmp/restart.txt”
  end
end

after :deploy, “passenger:restart”