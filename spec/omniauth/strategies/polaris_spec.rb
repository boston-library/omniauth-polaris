# frozen_string_literal: true

require 'spec_helper'

describe 'OmniAuth::Strategies::Polaris' do
  def app
    Rack::Builder.new do
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider OmniAuth::Strategies::Polaris, name: 'polaris', title: 'MyPolaris Form', http_uri: 'https://blah.org/PAPIService/REST/public/v1/1000/100/1/patron/', access_key: 'F9998888-A000-1111-C22C-CC3333BB4444', access_id: 'API', method: 'POST'
      end
      run ->(env) { [404, { 'Content-Type' => 'text/plain' }, [env.key?('omniauth.auth').to_s]] }
    end.to_app
  end

  def session
    last_request.env['rack.session']
  end

  it 'is expected to add a camelization for itself' do
    expect(OmniAuth::Utils.camelize('polaris')).to eq('Polaris')
  end

  describe '/auth/polaris' do
    before { post '/auth/polaris' }

    it 'is expected to display a form' do
      expect(last_response.status).to be(200)
      expect(last_response.body).to include('<form')
    end

    it 'is expected to have the callback as the action for the form' do
      expect(last_response.body).to include('/auth/polaris/callback')
    end

    it 'is expected to have a text field for each of the fields' do
      expect(last_response.body.scan('<input').size).to eq(2)
    end

    it 'is expected to have a label of the form title' do
      expect(last_response.body.scan('MyPolaris Form').size).to be > 1
    end
  end

  describe 'post /auth/polaris/callback' do
    before do
      allow(OmniAuth::Polaris::Adaptor).to receive(:new).and_return(adaptor)
    end

    let!(:adaptor) { instance_double(OmniAuth::Polaris::Adaptor) }

    context 'when failure' do
      before do
        allow(adaptor).to receive(:authenticate_patron).and_return(nil)
      end

      it 'is expected to fail! with :missing_credentials' do
        post('/auth/polaris/callback', {})
        expect(last_request.env['omniauth.error']).to be_a_kind_of(OmniAuth::Strategies::Polaris::MissingCredentialsError)
        expect(last_request.env['omniauth.error.type']).to be(:missing_credentials)
      end

      it 'is expected to redirect to error page' do
        post('/auth/polaris/callback', { barcode: 'ping', pin: 'password' })
        expect(last_response).to be_redirect
        expect(last_response.headers['Location']).to match(/invalid_credentials/)
      end
    end

    context 'when successful' do
      let(:auth_hash) { last_request.env['omniauth.auth'] }
      let(:patron_user_hash) do
        {
          'PAPIErrorCode' => '0',
          'Barcode' => '29999999999999',
          'ValidPatron' => 'true',
          'PatronID' => '111111',
          'PatronCodeID' => '27',
          'AssignedBranchID' => '3',
          'PatronBarcode' => '29999999999999',
          'AssignedBranchName' => 'BPL - Central',
          'ExpirationDate' => '2026-02-19T00:00:00',
          'OverridePasswordUsed' => 'false',
          'NameFirst' => 'Test',
          'NameLast' => 'Patron',
          'NameMiddle' => '',
          'EmailAddress' => 'test.patron@example.com',
          'PhoneNumber' => '555-555-5555'
        }
      end

      before do
        allow(adaptor).to receive(:authenticate_patron).and_return(patron_user_hash)
        post('/auth/polaris/callback', { barcode: '29999999999999', pin: '12345678' })
      end

      it 'is expected to map user info' do
        expect(auth_hash.info.barcode).to eq('29999999999999')
        expect(auth_hash.info.valid_patron).to eq('true')
        expect(auth_hash.info.patron_id).to eq('111111')
        expect(auth_hash.info.assigned_branch_id).to eq('3')
        expect(auth_hash.info.assigned_branch_name).to eq('BPL - Central')
      end
    end
  end
end
