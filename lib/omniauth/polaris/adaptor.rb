# frozen_string_literal: true

module OmniAuth
  module Polaris
    class Adaptor
      VALID_ADAPTER_CONFIGURATION_KEYS = [:access_id, :access_key, :method, :http_uri].freeze
      MUST_HAVE_KEYS = [:access_id, :access_key, :method, :http_uri].freeze
      METHOD = { :GET => :GET }.freeze

      attr_reader :config

      def self.validate(configuration = {})
        message = []
        MUST_HAVE_KEYS.each do |name|
          message << name if configuration[name].nil?
        end
        raise Polaris::ConfigurationError.new(message.join(' ,') + ' MUST be provided') unless message.empty?
      end

      def initialize(configuration = {})
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

        # Basic shared input variables
        pin = args[:pin]
        barcode = args[:barcode]
        http_date = Time.now.in_time_zone('GMT').strftime('%a, %d %b %Y %H:%M:%S %Z')

        # Authorization hash component
        http_uri_with_barcode =  @http_uri + barcode
        concated_string = "#{@method}#{@http_uri}#{barcode}#{http_date}#{pin}"
        sha1_sig = Base64.strict_encode64("#{OpenSSL::HMAC.digest('sha1', @access_key, concated_string)}")
        xml_response = HTTP.get http_uri_with_barcode, { 'PolarisDate' => http_date, 'Authorization' => "PWS #{@access_id}:#{sha1_sig}" }
        authorization_response = Hash.from_xml xml_response

        #Details hash component
        http_basic_data_get = "#{@http_uri}#{barcode}/basicdata"
        concated_string = @method + http_basic_data_get + http_date + pin
        sha1_sig = Base64.strict_encode64("#{OpenSSL::HMAC.digest('sha1', @access_key, concated_string)}")
        xml_response = HTTP.get http_basic_data_get, { 'PolarisDate' => http_date, 'Authorization' => "PWS #{@access_id}:#{sha1_sig}" }
        details_response = Hash.from_xml xml_response

        #Add some of the basic details to a single hash, using the authorization as the base.
        authorization_response['PatronValidateResult']['NameFirst'] = details_response.dig('PatronBasicDataGetResult', 'PatronBasicData', 'NameFirst')
        authorization_response['PatronValidateResult']['NameLast'] = details_response.dig('PatronBasicDataGetResult', 'PatronBasicData', 'NameLast')
        authorization_response['PatronValidateResult']['NameMiddle'] = details_response.dig('PatronBasicDataGetResult', 'PatronBasicData', 'NameMiddle')
        authorization_response['PatronValidateResult']['PhoneNumber'] = details_response.dig('PatronBasicDataGetResult', 'PatronBasicData', 'PhoneNumber')
        authorization_response['PatronValidateResult']['EmailAddress'] = details_response.dig('PatronBasicDataGetResult', 'PatronBasicData', 'EmailAddress')

        authorization_response['PatronValidateResult']
      end

      private

      def ensure_method(method = 'get')
        normalized_method = method.to_s.upcase.to_sym
        return METHOD[normalized_method] if METHOD.key?(normalized_method)

        available_methods = METHOD.keys.collect { |m| m.inspect }.join(', ')
        format = "%s is not one of the available connect methods: %s"
        raise Polaris::ConfigurationError, format % [method.inspect, available_methods]
      end
    end
  end
end
