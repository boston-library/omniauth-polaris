# frozen_string_literal: true

module OmniAuth
  module Strategies
    class Polaris
      class MissingCredentialsError < StandardError; end

      include OmniAuth::Strategy

      CONFIG = {
          'barcode' => 'barcode',
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

      option :title, 'Polaris Authentication' #default title for authentication form

      def request_phase
        OmniAuth::Polaris::Adaptor.validate @options

        OmniAuth::Form.build(title: options.fetch(:title, 'Polaris Authentication'), url: callback_path) do |f|
          f.text_field 'Barcode', 'barcode'
          f.password_field 'PIN', 'pin'
          f.button 'Sign In'
        end.to_response
      end

      def callback_phase
        @adaptor = OmniAuth::Polaris::Adaptor.new @options

        raise MissingCredentialsError.new('Missing login credentials') if request['barcode'].nil? || request['pin'].nil?

        begin
          @polaris_user_info = @adaptor.bind_as(:barcode => request['barcode'], :pin => request['pin'])
          return fail!(:invalid_credentials) if !@polaris_user_info

          @user_info = self.class.map_user(@polaris_user_info)

          super
        rescue Exception => e
          return fail!(:polaris_error, e)
        end
      end

      uid do
        request['barcode']
      end

      info do
        @user_info
      end

      extra do
        { raw_info: @polaris_user_info }
      end

      def self.map_user(object)
        user = {}
        CONFIG.dup.each do |key, value|
          case value
          when String
            user[key.to_sym] = object[value.to_sym] if object[value.to_sym]
          when Array
            #value.each {|v| (user[key] = object[v.downcase.to_sym].first; break;) if object[v.downcase.to_sym]}
            value.each {|v| (user[key] = object[v.downcase.to_sym]; break;) if object[v.downcase.to_sym]}
          when Hash
            value.map do |key1, value1|
              pattern = key1.dup
              value1.each_with_index do |v,i|
                #part = ''; v.collect(&:downcase).collect(&:to_sym).each {|v1| (part = object[v1].first; break;) if object[v1]}
                part = ''; v.collect(&:downcase).collect(&:to_sym).each { |v1| (part = object[v1]; break;) if object[v1] }
                pattern.gsub!("%#{i}", part || '')
              end
              user[key] = pattern
            end
          end
        end
        user
      end
    end
  end
end

OmniAuth.config.add_camelization 'polaris', 'Polaris'
