require 'rubygems'
require 'bundler/setup'

##
# Rune.rb - a gameserver written in Ruby targeting the 317/377 protocol(s) of the popular MMORPG, RuneScape.
# @author Pat W.
namespace :rrb do

  desc "Clears logs from the \"data/log\" directory"
  task :clear_logs do
    Dir.glob('data/logs/*').each do |file|
      puts "Removing Log #{file}"
      File.delete(file)
    end
    puts 'Cleared logs.'
  end

  desc "Launches an instance of the game server using an EventMachine reactor."
  task :launch_em do
    require_relative 'app/rune'

    RuneRb::System::Environment.init
    RuneRb::System::Controller.instance.autorun
  end

  ####
  # Development Tasks
  ####
  namespace :dev do

    desc "Launches a development instance of the game server application."
    task :run do 
      Bundler.require(:dev)
    end

    desc "Builds the Docker container for the Rune.rb framework."
    task build_release: ['rrb:dev:prep_release'] do
      Kernel.system('docker', 'build', '-t', 'sickday/rrb:latest', '.')
      sleep(3)
      Kernel.system('docker', 'push', 'sickday/rrb:latest')
      sleep(15)
      Kernel.system('docker-compose', 'build')
      puts 'Built and released.'
    end

    desc "Pushes current project to staging environment."
    task prep_release: ['rrb:clear_logs'] do
      # Remove existing release files
      Dir.chdir('release/') do
        puts `rm -rfv ./*` # Remove directory contents.
        sleep(1)
        puts Dir.empty?('.') ? 'Cleared previous release files.' : "Failed to remove some release files: #{Dir['.'].sort}"
        puts `cp -rv ../app ./`
        puts `cp -rv ../data ./`
        puts `cp -rv ../Dockerfile ./`
        puts `cp -rv ../docker-compose.yml ./`
        puts `cp -rv  ../Gemfile ./`
        puts `cp -rv ../LICENSE ./`
        puts `cp -rv ../ReadMe.md ./`
        puts `cp -rv #{__FILE__} ./`
        sleep(1)
      end
      puts 'Release prepared.'
    end

    Rake::Task['rrb:dev:run'].enhance { Rake::Task['rrb:launch_em'].invoke }
  end

  ####
  # Live Tasks
  ####
  namespace :live do

    desc "Launches a development instance of the game server application."
    task :run do 
      Bundler.require(:live)
    end

    Rake::Task['rrb:live:run'].enhance { Rake::Task['rrb:launch_em'].invoke }
  end

  ####
  # Testing Tasks
  ####
  namespace :test do

    desc "Runs all specs in the \"spec/\" folder using RSpec."
    task :run_specs do
      Dir.glob('spec/*').each { Kernel.system('rspec', _1) }
    end

    desc "Runs all tests in the \"test/\" folder using Minitest."
    task :run_tests do
      Dir.glob('test/*').each { Kernel.system('ruby', _1) }
    end
  end
end
