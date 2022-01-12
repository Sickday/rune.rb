require 'rubygems'
require 'bundler/setup'

##
# Rune.rb - a gameserver written in Ruby targeting the 317/377 protocol(s) of the popular MMORPG, RuneScape.
# @author Pat W.
#
# {rune_rb}
namespace :rrb do

  # Clears logs from the `log/`
  #
  # {rune_rb:clear_logs}
  task :clear_logs do
    Dir.glob('data/logs/*').each do |file|
      puts "Removing Log #{file}"
      File.delete(file)
    end
    puts 'Cleared logs.'
  end

  # Launch the app.
  task :launch do
    require_relative 'app/rune'

    RuneRb::System::Environment.init
    RuneRb::System::Controller.instance.autorun
  end

  ####
  # Development Tasks
  ####
  #
  # {rune_rb:devel}
  namespace :dev do

    # Launches an instance of the game server using an EventMachine reactor.
    #
    # {rune_rb:devel:launch}
    task :run do
      Bundler.require(:dev)
    end

    # Builds the Docker container for the Rune.rb framework.
    #
    # {rune_rb:devel:build_container}
    task :build_release do
      Kernel.system('docker-compose', 'build')
      sleep(1)
      Kernel.system('docker', 'push', 'sickday/rune.rb-app:latest')
      sleep(1)
      puts 'Built and released.'
    end

    # Pushes current project to staging environment.
    #
    # {rune_rb:devel:release}
    task :release => ['rune_rb:clear_logs'] do
      # Remove existing release files
      Dir.chdir('release/') do
        puts `rm -rfv ./*`  # Remove directory contents.
        sleep(1)
        puts Dir.empty?('.') ? 'Cleared previous release files.' : "Failed to remove some release files: #{Dir['.'].sort}"
        puts `cp -rv ../app ./`
        puts `cp -rv ../data ./`
        puts `cp -rv #{__FILE__} ./`
        sleep(1)
      end
      puts 'Completed release.'
    end

    Rake::Task['rrb:dev:run'].enhance { Rake::Task['rrb:launch'].invoke }
  end

  ####
  # Live Tasks
  ####
  #
  # {rune_rb:live}
  namespace :live do

    # Run the application in live mode.
    # {rune_rb:live:launch}
    task :run do
      Bundler.require(:live)
    end

    Rake::Task['rrb:live:run'].enhance { Rake::Task['rrb:launch'].invoke }
  end

  ####
  # Testing Tasks
  ####
  #
  # {rune_rb:testing}
  namespace :test do

    # Runs all specs in the `spec/` folder using RSpec.
    #
    # {rune_rb:testing:run_specs}
    task :run_specs do
      Dir.glob('spec/*').each { Kernel.system('rspec', _1) }
    end

    # Runs all tests in the `test/` folder using Minitest.
    #
    # {rune_rb:testing:run_tests}
    task :run_tests do
      Dir.glob('test/*').each { Kernel.system('ruby', _1) }
    end
  end
end
