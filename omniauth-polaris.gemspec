# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'omniauth/polaris/version'

Gem::Specification.new do |gem|
  gem.name = 'omniauth-polaris'
  gem.version = OmniAuth::Polaris::VERSION.dup
  gem.authors = ['Steven Anderson', 'Ben Barber']
  gem.email = ['sanderson@bpl.org', 'bbarber@bpl.org']
  gem.description = 'A Polaris API strategy for OmniAuth.'
  gem.summary = 'A Polaris API strategy for OmniAuth.'
  gem.homepage = 'https://github.com/boston-library/omniauth-polaris'

  gem.required_ruby_version = '>= 2.6.10'

  gem.add_dependency 'activesupport', '< 7'
  gem.add_dependency 'http', '~> 5.1'
  gem.add_dependency 'omniauth', '~> 2.1.0'

  gem.add_development_dependency 'awesome_print', '~> 1.9.2'
  gem.add_development_dependency 'bundler', '>= 1.3.0'
  gem.add_development_dependency 'libnotify', '~> 0.9.3'
  gem.add_development_dependency 'pry', '~> 0.14'
  gem.add_development_dependency 'rspec', '~> 3.12'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.require_paths = ['lib']
end
