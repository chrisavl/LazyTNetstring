require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version_file    = Dir['lib/*/{*/,}version.rb'].first
  version = ''
  # let's figure out the version
  wrapper = Module.new
  wrapper.module_eval File.read(version_file)
  wrapper.constants.map { |n| wrapper.const_get(n) }.each do |c|
    if c.const_defined? :VERSION
      version = c::VERSION
    elsif nested = c.constants.detect { |n| c.const_get(n).const_defined? :VERSION }
      version = nested::VERSION
    end
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "role_model #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
