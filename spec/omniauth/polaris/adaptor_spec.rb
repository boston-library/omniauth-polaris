# frozen_string_literal: true

require 'spec_helper'

describe OmniAuth::Polaris::Adaptor do
  describe 'initialize' do
    let(:patron_url) { 'http://blah.org/PAPIService/REST/public/v1/1000/100/1/patron/' }

    it 'should throw exception when must have field is not set' do
      #[:host, :port, :method, :bind_dn]
      expect{ OmniAuth::Polaris::Adaptor.new( { http_uri: patron_url, method: 'GET' })}.to raise_error(OmniAuth::Polaris::ConfigurationError)
    end

    it 'should throw exception when method is not supported' do
      expect { OmniAuth::Polaris::Adaptor.new({ http_uri: patron_url, method: 'POST', access_key: 'F9998888-A000-1111-C22C-CC3333BB4444', access_id: 'API' })}.to raise_error(OmniAuth::Polaris::ConfigurationError)
    end
  end
end
