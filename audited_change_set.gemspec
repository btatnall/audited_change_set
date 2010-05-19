# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{audited_change_set}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Chelimsky", "Brian Tatnall", "Nate Jackson", "Corey Haines"]
  s.date = %q{2010-05-19}
  s.description = %q{change_set for acts_as_audited}
  s.email = %q{dchelimsky@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".document",
     ".gitignore",
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
  s.homepage = %q{http://github.com/dchelimsky/audited_change_set}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{change_set for acts_as_audited}
  s.test_files = [
    "spec/db/schema.rb",
     "spec/audited_change_set/change_spec.rb",
     "spec/audited_change_set/change_set_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
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

