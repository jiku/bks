set :application,   "sonik.nu"
set :domain,        "sonik.nu"
set :repository,    "git://github.com/prism/bks.git"
set :use_sudo,      false
set :deploy_to,     "/home/#{application}"
set :scm,           "git"
set :scm_username,  "prism"
set :scm_password,  "megaman"
set :user,          "jiku"

role :app, domain
role :web, domain
role :db,  domain, :primary => true

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end