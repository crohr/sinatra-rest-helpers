require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sinatra-rest-helpers"
    gem.summary = %Q{Adds useful helpers for REST applications developed with Sinatra.}
    gem.description = %Q{A set of helpers for sinatra apps that expose REST resources.}
    gem.email = "cyril.rohr@gmail.com"
    gem.homepage = "http://github.com/cryx/sinatra-rest-helpers"
    gem.authors = ["Cyril Rohr"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end




task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end
