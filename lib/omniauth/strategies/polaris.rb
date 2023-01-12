# frozen_string_literal: true

module OmniAuth
  module Strategies
    class Polaris
      class MissingCredentialsError < StandardError; end
      class InvalidCredentialsError < StandardError; end

      include OmniAuth::Strategy

      USER_MAP = {
        'barcode' => 'Barcode',
        'valid_patron' => 'ValidPatron',
        'patron_id' => 'PatronID',
        'assigned_branch_id' => 'AssignedBranchID',
        'assigned_branch_name' => 'AssignedBranchName',
        'first_name' => 'NameFirst',
        'last_name' => 'NameLast',
        'middle_name' => 'NameMiddle',
        'phone_number' => 'PhoneNumber',
        'email' => 'EmailAddress'
      }.freeze

      def self.map_user(polaris_user_info)
        USER_MAP.each_with_object({}) do |(user_key, polaris_user_key), user_hash|
          user_hash[user_key.to_sym] = polaris_user_info[polaris_user_key] if polaris_user_info[polaris_user_key].present?
        end
      end

      option :title, 'Polaris Authentication' # default title for authentication form

      def request_phase
        OmniAuth::Polaris::Adaptor.validate!(@options)

        OmniAuth::Form.build(title: options.fetch(:title, 'Polaris Authentication'), url: callback_path) do |f|
          f.text_field 'Barcode', 'barcode'
          f.password_field 'PIN', 'pin'
          f.button 'Sign In'
        end.to_response
      end

      # rubocop:disable Style/SignalException
      def callback_phase
        @adaptor = OmniAuth::Polaris::Adaptor.new(@options)

        fail(MissingCredentialsError, 'Missing login credentials') if %w[barcode pin].any? { |request_key| request.params[request_key].blank? }

        @polaris_user_info = @adaptor.authenticate_patron(pin: request.params['pin'], barcode: request.params['barcode'])

        fail(InvalidCredentialsError, 'Invalid User Credentials!') if @polaris_user_info.blank?

        @user_info = self.class.map_user(@polaris_user_info)

        super
      rescue MissingCredentialsError => e
        fail!(:missing_credentials, e)
      rescue InvalidCredentialsError => e
        fail!(:invalid_credentials, e)
      rescue StandardError => e
        fail!(:polaris_error, e)
      end
      # rubocop:enable Style/SignalException

      uid do
        @user_info[:barcode]
      end

      info do
        @user_info
      end

      extra do
        { raw_info: @polaris_user_info }
      end
    end
  end
end

OmniAuth.config.add_camelization 'polaris', 'Polaris'
