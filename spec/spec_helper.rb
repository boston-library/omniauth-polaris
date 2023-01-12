# frozen_string_literal: true

$:.unshift File.expand_path(__dir__)
$:.unshift File.expand_path('../lib', __dir__)

ENV['RACK_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start

require 'pry'
require 'awesome_print'
require 'rspec'
require 'rack/test'
require 'omniauth-polaris'

OmniAuth.config.request_validation_phase = nil

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
