require 'base64'
require 'cgi'
require 'openssl'
require 'rest_client'

module OmniAuth
  module Polaris
    class Adaptor
      class PolarisError < StandardError; end
      class ConfigurationError < StandardError; end
      class AuthenticationError < StandardError; end
      class ConnectionError < StandardError; end

      VALID_ADAPTER_CONFIGURATION_KEYS = [:access_id, :access_key, :method, :http_uri]

      MUST_HAVE_KEYS = [:access_id, :access_key, :method, :http_uri]

      METHOD = {
          :GET => :GET
      }

      attr_reader :config

      def self.validate(configuration={})
        message = []
        MUST_HAVE_KEYS.each do |name|
          message << name if configuration[name].nil?
        end
        raise ArgumentError.new(message.join(",") +" MUST be provided") unless message.empty?
      end

      def initialize(configuration={})
        Adaptor.validate(configuration)
        @configuration = configuration.dup
        @logger = @configuration.delete(:logger)
        VALID_ADAPTER_CONFIGURATION_KEYS.each do |name|
          instance_variable_set("@#{name}", @configuration[name])
        end

        @config = {
            :http_uri => @http_uri,
            :method => @method,
            :access_key => @access_key,
            :access_id => @access_id
        }

        method = ensure_method(@method)

      end

      public
      def bind_as(args = {})
        response = false
        pin = args[:pin]
        barcode = args[:barcode]
        http_uri_with_barcode =  @http_uri + barcode

        http_date = Time.now.in_time_zone("GMT").strftime("%a, %d %b %Y %H:%M:%S %Z")

        concated_string = @method + @http_uri + barcode + http_date + pin
        sha1_sig = Base64.strict_encode64("#{OpenSSL::HMAC.digest('sha1',@access_key, concated_string)}")
        xml_response = RestClient.get http_uri_with_barcode, {'PolarisDate' => http_date, 'Authorization' =>  "PWS " + @access_id + ":" + sha1_sig}
        hashed_response = Hash.from_xml xml_response

        hashed_response["PatronValidateResult"]
      end

      private
      def ensure_method(method)
        method ||= "get"
        normalized_method = method.to_s.upcase.to_sym
        return METHOD[normalized_method] if METHOD.has_key?(normalized_method)

        available_methods = METHOD.keys.collect {|m| m.inspect}.join(", ")
        format = "%s is not one of the available connect methods: %s"
        raise ConfigurationError, format % [method.inspect, available_methods]
      end




    end
  end
end