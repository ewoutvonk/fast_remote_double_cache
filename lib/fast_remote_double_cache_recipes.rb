Capistrano::Configuration.instance(:must_exist).load do
  # ---------------------------------------------------------------------------
  # This is a recipe definition file for Capistrano. The tasks are documented
  # below.
  # ---------------------------------------------------------------------------
  # The original copy of this file is distributed under the terms of the MIT
  # license by 37signals, LLC, and is copyright (c) 2008 by the same. See the
  # LICENSE file distributed with this file for the complete text of the license.
  # ---------------------------------------------------------------------------
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

  set :deploy_via, :fast_remote_cache
  set :scm, :indirect_git
  
  set :remote_repository, repository
  set(:repository) { File.join(deploy_to, 'mirror', application) }
  
  set :fast_remote_double_cache_skip_tasks, false
  set :fast_remote_double_cache_use_bundler, true
  set :fast_remote_double_cache_bundle_path, 'vendor/bundle'
  set :fast_remote_double_cache_without_groups, 'development test'

  namespace :fast_remote_cache do

    desc <<-DESC
      Perform any setup required by fast_remote_cache. This is called
      automatically after deploy:setup, but may be invoked manually to configure
      a new machine. It is also necessary to invoke when you are switching to the
      fast_remote_cache strategy for the first time.
    DESC
    task :setup, :except => { :no_release => true } do
      if deploy_via == :fast_remote_cache
        strategy.setup!
      else
        logger.important "you're including the fast_remote_cache strategy, but not using it!"
      end
    end

    desc <<-DESC
      Updates the remote cache. This is handy for either priming a new box so
      the cache is all set for the first deploy, or for preparing for a large
      deploy by making sure the cache is updated before the deploy goes through.
      Either way, this will happen automatically as part of a deploy; this task
      is purely convenience for giving admins more control over the deployment.
    DESC
    task :prepare, :except => { :no_release => true } do
      if deploy_via == :fast_remote_cache
        strategy.prepare!
      else
        logger.important "#{current_task.fully_qualified_name} only works with the fast_remote_cache strategy"
      end
    end
  end

  namespace :deploy do  
    namespace :prepare do
    
      desc "prepare the deployment"
      task :default do
        clone_and_checkout_git_repo
        top.fast_remote_cache.prepare
        tasks
      end
      
      task :clone_and_checkout_git_repo do
        run <<-EOF
          [ ! -d "#{repository}" ] && git clone #{remote_repository} #{repository} ;
          cd "#{repository}" ;
          git reset --hard ;
          git checkout #{branch} ;
          git pull --rebase ;
          cp -a #{shared_path}/config/* #{repository}/config/
        EOF
      end
    
      task :tasks do
        run "bash -l -c '#{RVM_USE_CMD}cd #{repository} ; bundle install --path vendor/bundle --without development test'"
        run "cd #{repository} ; rake deploy:prepare RAILS_ENV=#{rails_env}"
      end

      task :check_stamp do
        if !File.exists?('.deploy.prepare')
          abort "You have to run deploy:prepare first!"
        end
      end
      
      task :stamp do
        system("touch .deploy.prepare")
      end

      task :remove_stamp do
        system("rm -f .deploy.prepare")
      end
    
    end
  end

  after "deploy:setup", "fast_remote_cache:setup"
  if fetch(:rails_env, "production").to_s == "production"
    after "deploy:prepare", "deploy:prepare:stamp"
    before "deploy", "deploy:prepare:check_stamp"
    before "deploy:migrations", "deploy:prepare:check_stamp"
    after "deploy", "deploy:prepare:remove_stamp"
    after "deploy:migrations", "deploy:prepare:remove_stamp"
  else
    before "deploy", "deploy:prepare"
    before "deploy:migrations", "deploy:prepare"
  end
end