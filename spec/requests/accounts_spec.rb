# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Accounts', type: :request do
  subject(:deposit_request) do
    post deposit_account_path(account), params: { deposit: { amount_cents: amount_cents } }
  end

  let(:account) { create(:account) }

  before { deposit_request }

  describe 'POST /accounts/:id/deposit' do
    context 'with a positive amount' do
      let(:amount_cents) { 5_000 }

      it 'responds 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'reports the new balance' do
        expect(response.parsed_body['balance_cents']).to eq(5_000)
      end
    end

    context 'with a non-positive amount' do
      let(:amount_cents) { 0 }

      it 'responds 422 Unprocessable' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns an error message' do
        expect(response.parsed_body).to have_key('error')
      end
    end
  end
end
