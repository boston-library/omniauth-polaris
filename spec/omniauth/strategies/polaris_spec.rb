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
    expect( OmniAuth::Utils.camelize('polaris') ).to eq('Polaris')
  end

  describe '/auth/polaris' do
    before(:each){ get '/auth/polaris' }

    it 'should display a form' do
      expect(last_response.status).to eql(200)
      expect(last_response.body).to include("<form")
    end

    it 'should have the callback as the action for the form' do
      expect(last_response.body).to include("action='/auth/polaris/callback'")
    end

    it 'should have a text field for each of the fields' do
      expect(last_response.body.scan('<input').size).to eq(2)
    end
    it 'should have a label of the form title' do
      expect(last_response.body.scan('MyPolaris Form').size).to be > 1
    end

  end

  describe 'post /auth/polaris/callback' do
    before(:each) do
      @adaptor = double(OmniAuth::Polaris::Adaptor, {:barcode => '29999999999999'})
      allow(OmniAuth::Polaris::Adaptor).to receive(:new).and_return(@adaptor)
    end
    context 'failure' do
      before(:each) do
        allow(@adaptor).to receive(:bind_as).and_return(false)
      end
      it 'should raise MissingCredentialsError' do
        expect{ post('/auth/polaris/callback', {}) }.to raise_error OmniAuth::Strategies::Polaris::MissingCredentialsError
      end
      it 'should redirect to error page' do
        post('/auth/polaris/callback', {:barcode => 'ping', :pin => 'password'})
        expect(last_response).to be_redirect
        expect(last_response.headers['Location']).to match(%r{invalid_credentials})
      end
    end

    context 'success' do
      let(:auth_hash){ last_request.env['omniauth.auth'] }
      before(:each) do
        allow(@adaptor).to receive(:bind_as).and_return({:PAPIErrorCode => "0", :barcode => '29999999999999', :ValidPatron => 'true', :PatronID => '111111', :PatronCodeID => '27',
                                            :AssignedBranchID => '3', :PatronBarcode => '29999999999999', :AssignedBranchName => 'BPL - Central', :ExpirationDate => '2015-09-20T00:00:00', :OverridePasswordUsed =>'false'})
        #
        post('/auth/polaris/callback', {:barcode => '29999021413588', :pin => '0407'})
      end

      # it 'should raise MissingCredentialsError' do
      #   should_not raise_error OmniAuth::Strategies::Polaris::MissingCredentialsError
      # end
      it 'should map user info' do
        expect(auth_hash.info.barcode).to eq('29999999999999')
        expect(auth_hash.info.valid_patron).to eq('true')
        expect(auth_hash.info.patron_id).to eq('111111')
        expect(auth_hash.info.assigned_branch_id).to eq('3')
        expect(auth_hash.info.assigned_branch_name).to eq('BPL - Central')
      end
    end
  end
end
