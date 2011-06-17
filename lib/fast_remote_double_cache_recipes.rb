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

  # don't change this one, it's internal
  set :fast_remote_double_cache_remote_repository, repository
  set(:repository) { File.join(deploy_to, 'mirror', application) }
  
  set :fast_remote_double_cache_skip_tasks, false
  set :fast_remote_double_cache_use_bundler, true
  set :fast_remote_double_cache_bundle_path, 'vendor/bundle'
  set :fast_remote_double_cache_without_groups, %w(development test)
  set :fast_remote_double_cache_rvm_use_cmd, ''
  # this long line of shell code sets the correct architecture flags for bundling based on OS type and bits of the system
  set :fast_remote_double_cache_os, :linux # or :osx
  set :fast_remote_double_cache_bits, 64
  set(:fast_remote_double_cache_arch_flags) { fast_remote_double_cache_os == :osx ? "ARCHFLAGS='-arch #{fast_remote_double_cache_bits.to_i == 64 ? "x64_64" : "i386"}'" : "CFLAGS='-m#{fast_remote_double_cache_bits}' LDFLAGS='-m#{fast_remote_double_cache_bits})'" }

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
        deploy_tasks
      end
      
      task :clone_and_checkout_git_repo do
        run <<-EOF
          [ ! -d "#{repository}" ] && git clone #{fast_remote_double_cache_remote_repository} #{repository} ;
          cd "#{repository}" ;
          git add -A ;
          git reset --hard ;
          git checkout #{branch} ;
          git pull --rebase ;
          cp -a #{shared_path}/config/* #{repository}/config/
        EOF
      end
    
      task :deploy_tasks do
        if fast_remote_double_cache_use_bundler
          run "bash -l -c '#{fast_remote_double_cache_rvm_use_cmd}cd #{repository} ; #{fast_remote_double_cache_arch_flags} bundle install --path #{fast_remote_double_cache_bundle_path} --without #{fast_remote_double_cache_without_groups.join(' ')}'"
        end
        unless fast_remote_double_cache_skip_tasks
          vars = { :RAILS_ENV => rails_env }
          vars[:STAGE] = stage if exists?(:stage)
          run "bash -l -c '#{fast_remote_double_cache_rvm_use_cmd}cd #{repository} ; #{fast_remote_double_cache_use_bundler ? "bundle exec" : ""} rake deploy:prepare #{vars.collect { |k,v| "#{k}='#{v}'" }.join(' ')}'"
        end
      end

      task :check_stamp do
        stamp_file = ".deploy.prepare#{exists?(:stage) ? ".#{stage}" : ""}"
        if !File.exists?(stamp_file)
          abort "You have to run deploy:prepare first!"
        end
      end
      
      task :stamp do
        stamp_file = ".deploy.prepare#{exists?(:stage) ? ".#{stage}" : ""}"
        system("touch #{stamp_file}")
      end

      task :remove_stamp do
        stamp_file = ".deploy.prepare#{exists?(:stage) ? ".#{stage}" : ""}"
        system("rm -f #{stamp_file}")
      end
    
    end
  end

  after "deploy:setup", "fast_remote_cache:setup"
  before "deploy:prepare", "fast_remote_cache:setup" # make sure the 'copy' script is on the server
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