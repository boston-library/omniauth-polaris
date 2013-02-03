require 'spec_helper'
describe "OmniAuth::Polaris::Adaptor" do

  describe 'initialize' do
    it 'should throw exception when must have field is not set' do
      #[:host, :port, :method, :bind_dn]
      lambda { OmniAuth::Polaris::Adaptor.new({http_uri: "http://blah.org/PAPIService/REST/public/v1/1000/100/1/patron/", method: 'GET'})}.should raise_error(ArgumentError)
    end

    it 'should throw exception when method is not supported' do
      lambda { OmniAuth::Polaris::Adaptor.new({http_uri: "http://blah.org/PAPIService/REST/public/v1/1000/100/1/patron/", method: 'POST', access_key: 'F9998888-A000-1111-C22C-CC3333BB4444', access_id: 'API'})}.should raise_error(OmniAuth::Polaris::Adaptor::ConfigurationError)
    end
  end

end