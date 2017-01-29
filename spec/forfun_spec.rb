# frozen_string_literal: true

require 'rack/test'
require 'forfun'

RSpec.describe 'Forfun' do
  shared_examples 'returns JSON' do
    it do
      subject
      expect(browser.last_response['Content-Type']).to eq('application/json')
    end
  end

  shared_examples 'returns status' do |status|
    it do
      subject
      expect(browser.last_response.status).to eq(status)
    end
  end

  let!(:browser) do
    Rack::Test::Session.new(Rack::MockSession.new(Forfun::App.instance))
  end

  describe '#get' do
    let(:data) { Hash[test: [1,2,3]] }

    before do
      get '/gg' do
        data
      end
    end

    context 'with valid path' do
      subject { browser.get '/gg' }

      it_behaves_like 'returns status', 200
      it_behaves_like 'returns JSON'

      it 'returns provided body' do
        browser.get '/gg'
        expect(browser.last_response.body).to eq(JSON.dump(data))
      end
    end

    context 'with invalid path' do
      subject { browser.get '/aa' }

      it_behaves_like 'returns status', 404
      it_behaves_like 'returns JSON'
    end

    context 'when defined w/o block' do
      before { get '/hh' }

      subject { browser.get '/hh' }

      it_behaves_like 'returns status', 200
      it_behaves_like 'returns JSON'

      it 'returns empty body' do
        browser.get '/hh'
        expect(browser.last_response.body).to eq(JSON.dump({}))
      end
    end
  end

  describe '#post' do
    let(:data) { Hash[test: 'PASSED'] }
    let(:input) { JSON.dump(data: data) }

    before do
      post '/gg' do |pars|
        pars[:data]
      end
    end

    context 'with valid path' do
      context 'with valid data' do
        subject { browser.post '/gg', {},  { input: input } }

        it_behaves_like 'returns status', 200
        it_behaves_like 'returns JSON'

        it 'returns provided body' do
          browser.post '/gg', {},  { input: input }
          expect(browser.last_response.body).to eq(JSON.dump(data))
        end
      end

      context 'with invalid data' do
        subject { browser.post '/gg', {},  { input: input[0..-2] } }

        it_behaves_like 'returns status', 422
        it_behaves_like 'returns JSON'
      end
    end

    context 'with invalid path' do
      subject { browser.post '/ggg', {},  { input: input } }

      it_behaves_like 'returns status', 404
      it_behaves_like 'returns JSON'
    end
  end
end
