# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "audited_change_set"
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Chelimsky", "Brian Tatnall", "Nate Jackson", "Corey Haines", "Justin Dell"]
  s.date = "2012-08-09"
  s.description = "change_set for acts_as_audited"
  s.email = "dchelimsky@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.markdown"
  ]
  s.files = [
    ".document",
    ".rspec",
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "audited_change_set.gemspec",
    "lib/audited_change_set.rb",
    "lib/audited_change_set/change.rb",
    "lib/audited_change_set/change_set.rb",
    "spec/audited_change_set/change_set_spec.rb",
    "spec/audited_change_set/change_spec.rb",
    "spec/db/schema.rb",
    "spec/spec_helper.rb",
    "specs.watchr"
  ]
  s.homepage = "http://github.com/dchelimsky/audited_change_set"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.17"
  s.summary = "change_set for acts_as_audited"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<acts_as_audited>, [">= 1.1.1"])
      s.add_development_dependency(%q<rspec>, [">= 2.0.0.beta.8"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
    else
      s.add_dependency(%q<acts_as_audited>, [">= 1.1.1"])
      s.add_dependency(%q<rspec>, [">= 2.0.0.beta.8"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
    end
  else
    s.add_dependency(%q<acts_as_audited>, [">= 1.1.1"])
    s.add_dependency(%q<rspec>, [">= 2.0.0.beta.8"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
  end
end

