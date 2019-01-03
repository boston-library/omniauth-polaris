# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth-polaris/version'
Gem::Specification.new do |gem|
  gem.name = "omniauth-polaris"
  gem.version = OmniAuth::Polaris::VERSION
  gem.authors = ["Steven Anderson", "Ben Barber"]
  gem.email = ["sanderson@bpl.org", "bbarber@bpl.org"]
  gem.description = %q{A Polaris API strategy for OmniAuth.}
  gem.summary = %q{A Polaris API strategy for OmniAuth.}
  gem.homepage = "https://github.com/boston-library/omniauth-polaris"

  gem.required_ruby_version = '~> 2.4'


  gem.add_dependency 'rest-client', '~> 2.0.2'

  gem.add_development_dependency 'omniauth', '~> 1.8.1'
  gem.add_development_dependency 'bundler', '>= 1.3.0'
  gem.add_development_dependency 'awesome_print'
  gem.add_development_dependency 'rspec', '~> 3.8'
  gem.add_development_dependency 'libnotify', '~> 0.9.3'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
