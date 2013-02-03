require 'spec_helper'
describe "OmniAuth::Strategies::Polaris" do


  class MyPolarisProvider < OmniAuth::Strategies::Polaris; end
  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use MyPolarisProvider, :name => 'polaris', :title => 'MyPolaris Form', :http_uri => 'http://blah.org/PAPIService/REST/public/v1/1000/100/1/patron/', :access_key => 'F9998888-A000-1111-C22C-CC3333BB4444', :access_id => 'API', :method => 'GET'
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  def session
    last_request.env['rack.session']
  end

  it 'should add a camelization for itself' do
    OmniAuth::Utils.camelize('polaris').should == 'Polaris'
  end

  describe '/auth/polaris' do
    before(:each){ get '/auth/polaris' }

    it 'should display a form' do
      last_response.status.should == 200
      last_response.body.should be_include("<form")
    end

    it 'should have the callback as the action for the form' do
      last_response.body.should be_include("action='/auth/polaris/callback'")
    end

    it 'should have a text field for each of the fields' do
      last_response.body.scan('<input').size.should == 2
    end
    it 'should have a label of the form title' do
      last_response.body.scan('MyPolaris Form').size.should > 1
    end

  end

  describe 'post /auth/polaris/callback' do
    before(:each) do
      @adaptor = mock(OmniAuth::Polaris::Adaptor, {:barcode => '29999999999999'})
      OmniAuth::Polaris::Adaptor.stub(:new).and_return(@adaptor)
    end
    context 'failure' do
      before(:each) do
        @adaptor.stub(:bind_as).and_return(false)
      end
      it 'should raise MissingCredentialsError' do
        lambda{post('/auth/polaris/callback', {})}.should raise_error OmniAuth::Strategies::Polaris::MissingCredentialsError
      end
      it 'should redirect to error page' do
        post('/auth/polaris/callback', {:barcode => 'ping', :pin => 'password'})
        last_response.should be_redirect
        last_response.headers['Location'].should =~ %r{invalid_credentials}
      end
    end

    context 'success' do
      let(:auth_hash){ last_request.env['omniauth.auth'] }
      before(:each) do
        @adaptor.stub(:bind_as).and_return({:PAPIErrorCode => "0", :barcode => '29999999999999', :ValidPatron => 'true', :PatronID => '111111', :PatronCodeID => '27',
                                            :AssignedBranchID => '3', :PatronBarcode => '29999999999999', :AssignedBranchName => 'BPL - Central', :ExpirationDate => '2015-09-20T00:00:00', :OverridePasswordUsed =>'false'})
        #
        post('/auth/polaris/callback', {:barcode => '29999021413588', :pin => '0407'})
      end

      it 'should raise MissingCredentialsError' do
        should_not raise_error OmniAuth::Strategies::Polaris::MissingCredentialsError
      end
      it 'should map user info' do
        auth_hash.info.barcode.should == '29999999999999'
        auth_hash.info.valid_patron.should == 'true'
        auth_hash.info.patron_id.should == '111111'
        auth_hash.info.assigned_branch_id.should == '3'
        auth_hash.info.assigned_branch_name.should == 'BPL - Central'
      end
    end
  end
end