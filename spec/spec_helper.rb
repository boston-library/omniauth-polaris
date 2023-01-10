# frozen_string_literal: true

$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start

require 'rspec'
require 'rack/test'
require 'pry'
require 'omniauth-polaris'
require 'omniauth/test'

OmniAuth.config.allowed_request_methods = %i[get post]

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, :type => :strategy
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
