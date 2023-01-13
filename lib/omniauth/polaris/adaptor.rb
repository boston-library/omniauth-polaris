# frozen_string_literal: true

module OmniAuth
  module Polaris
    class Adaptor
      REQUIRED_ADAPTER_CONFIG_KEYS = %i[access_id access_key method http_uri].freeze
      BASIC_USER_DATA_KEYS = %w[NameFirst NameLast NameMiddle PhoneNumber EmailAddress].freeze
      METHOD = { POST: :GET }.freeze

      attr_reader :config

      def self.validate!(configuration = {})
        message = REQUIRED_ADAPTER_CONFIG_KEYS.each_with_object([]) do |name, msg|
          next msg if configuration[name].present?

          msg << name
        end

        raise Polaris::ConfigurationError, "#{message.join(' ,')} MUST be provided" unless message.blank?
      end

      def initialize(configuration = {})
        self.class.validate!(configuration)

        @configuration = configuration.dup

        @logger = @configuration.delete(:logger)

        REQUIRED_ADAPTER_CONFIG_KEYS.each do |name|
          instance_variable_set("@#{name}", @configuration[name])
        end

        @config = {
          http_uri: @http_uri,
          method: @method,
          access_key: @access_key,
          access_id: @access_id
        }

        ensure_method!(@method)
        @polaris_method = METHOD[@method]
      end

      def authenticate_patron(pin:, barcode:)
        # According to the polaris api docs "Date must be within +/- 30 minutes of current time or request will fail"
        http_date = 15.minutes.from_now.in_time_zone('GMT').strftime('%a, %d %b %Y %H:%M:%S %Z')

        # Authorization hash component
        authorization_hash = authorization_response(pin, barcode, http_date)

        return if authorization_hash.blank?

        # Details hash component
        details_hash = details_response(pin, barcode, http_date)

        return if details_hash.blank? || details_hash.dig('PatronBasicDataGetResult', 'PatronBasicData').blank?

        patron_user_hash = authorization_hash['PatronValidateResult'].dup

        patron_user_hash.merge(details_hash.dig('PatronBasicDataGetResult', 'PatronBasicData').slice(*BASIC_USER_DATA_KEYS))
      end

      protected

      def authorization_response(pin, barcode, request_date)
        patron_validate_uri = "#{@http_uri}/patron/#{barcode}"
        validation_concated_string = "#{@polaris_method}#{patron_validate_uri}#{request_date}#{pin}"
        polaris_get_xml_response(patron_validate_uri, request_date, validation_concated_string)
      end

      def details_response(pin, barcode, request_date)
        patron_basic_data_uri = "#{@http_uri}#{barcode}/basicdata"
        details_concated_string = "#{@polaris_method}#{http_basic_data_uri}#{request_date}#{pin}"
        polaris_get_xml_response(patron_basic_data_uri, request_date, details_concated_string)
      end

      private

      def polaris_request_headers(request_date, concated_string)
        { 'Date' => request_date, 'Authorization' => "PWS #{@access_id}:#{sha1_sig(concated_string)}" }
      end

      def polaris_get_xml_response(uri, request_date, concated_string)
        xml_response = HTTP.get(uri, headers: polaris_request_headers(request_date, concated_string))

        return {} unless xml_response.status.success?

        Hash.from_xml(xml_response.body.to_s)
      rescue HTTP::Error, OpenSSL::SSL::SSLError => e
        raise Polaris::ConnectionError, "Could not connect to polaris due to the following error\n #{e.class.name}: #{e.message}"
      end

      def sha1_sig(concated_string)
        Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', @access_key, concated_string).to_s)
      end

      def ensure_method!(method = 'post')
        normalized_method = method.to_s.upcase.to_sym

        return normalized_method if METHOD.key?(normalized_method)

        available_methods = METHOD.keys.collect(&:inspect).join(', ')

        raise Polaris::ConfigurationError, "#{method} is not one of the available connect methods: #{available_methods}"
      end
    end
  end
end
