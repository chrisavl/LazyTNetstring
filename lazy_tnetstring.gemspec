Gem::Specification.new do |s|
  version_file    = Dir['lib/*/{*/,}version.rb'].first
  s.name          = 'lazy_tnetstring'
  s.summary       = 'Proxy that parses TNetstring lazily'
  s.description   = s.summary
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.authors       = ['Jesper Richter-Reichhelm', 'Martin Rehfeld']
  s.email         = 'jesper.richter-reichhelm@wooga.com'
  s.license       = 'MIT'
  s.require_paths = ['lib']

  github_user     = 'jrirei'
  s.homepage      = "http://github.com/#{github_user}/LazyTNetstring"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2'
  s.add_development_dependency 'autotest'
  s.add_development_dependency 'activesupport'
  s.add_development_dependency 'i18n'
  s.add_development_dependency 'tnetstring'

  # let's figure out the version
  wrapper = Module.new
  wrapper.module_eval File.read(version_file)
  wrapper.constants.map { |n| wrapper.const_get(n) }.each do |c|
    if c.const_defined? :VERSION
      s.version = c::VERSION
    elsif nested = c.constants.detect { |n| c.const_get(n).const_defined? :VERSION }
      s.version = nested::VERSION
    end
  end
end
