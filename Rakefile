require 'rubygems'
require 'rake/testtask'
require 'bundler/setup'

# Rune.rb - a gameserver written in Ruby targeting the 317/377 protocol(s) of the popular MMORPG, RuneScape.
# @author Pat W.
namespace :rrb do

  task :init_env do
    require_relative 'lib/rune'

    # Initialize Rune.rb environment
    RuneRb.init_env(fetch: true, force: true )

    # Setup DB
    RuneRb::Database.setup_database
  end

  desc "Clears logs from the \"data/log/\" directory"
  task :clear_logs do
    Dir.glob('data/logs/*').each do |file|
      puts "Removing Log #{file}"
      File.delete(file)
    end
    puts 'Cleared logs.'
  end

  desc "Launches an instance of the game server using an EventMachine reactor."
  task autorun: %w[rrb:init_env] do
    # Launch legacy controller
    RuneRb::Utils::LegacyController.instance.autorun
  end

  desc "Builds the Docker container for the Rune.rb framework."
  task build_release: ['rrb:prep_release'] do
    Kernel.system('docker', 'build', '-t', 'sickday/rrb:latest', '.')
    sleep(3)
    Kernel.system('docker', 'push', 'sickday/rrb:latest')
    puts 'Built and released.'
  end

  desc "Pushes current project to staging environment."
  task prep_release: ['rrb:clear_logs'] do
    # Remove existing release files
    Dir.chdir('release/') do
      puts `rm -rfv ./*` # Remove directory contents.
      sleep(1)
      puts Dir.empty?('.') ? 'Cleared previous release files.' : "Failed to remove some release files: #{Dir['.'].sort}"
      puts `cp -rv ../lib ./`
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

  # Testing Tasks
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
