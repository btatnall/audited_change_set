require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "audited_change_set"
    gem.summary = %Q{change_set for acts_as_audited}
    gem.description = gem.summary
    gem.email = "dchelimsky@gmail.com"
    gem.homepage = "http://github.com/dchelimsky/audited_change_set"
    gem.authors = ["David Chelimsky","Brian Tatnall", "Nate Jackson", "Corey Haines"]
    gem.add_dependency "acts_as_audited", ">= 1.1.1"
    gem.add_development_dependency "rspec", ">= 2.0.0.beta.8"
    gem.add_development_dependency "sqlite3-ruby", ">= 1.2.5"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
Rspec::Core::RakeTask.new(:spec)

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "audited_change_set #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
