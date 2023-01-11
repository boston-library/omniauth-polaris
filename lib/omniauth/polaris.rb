# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'base64'
require 'cgi'
require 'openssl'
require 'http'
require 'omniauth'
require 'omniauth/strategies/polaris'

module OmniAuth
  module Polaris
    class PolarisError < StandardError; end
    class ConfigurationError < StandardError; end
    class AuthenticationError < StandardError; end
    class ConnectionError < StandardError; end
  end
end

require 'omniauth/polaris/adaptor'
