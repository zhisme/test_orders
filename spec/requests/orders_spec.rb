# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  subject(:complete_request) { post complete_order_path(id: target_id) }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:order) { create(:order, user: user, amount_cents: 1_000) }
  let(:target_id) { order.id }

  before { Accounts::Deposit.call(account, 10_000) }

  describe 'POST /orders/:id/complete' do
    context 'when the order is created and funded' do
      before { complete_request }

      it 'responds 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'reports the order as success' do
        expect(response.parsed_body['status']).to eq('success')
      end
    end

    context 'when the order is already success' do
      let(:order) { create(:order, user: user, status: :success) }

      before { complete_request }

      it 'responds 409 Conflict' do
        expect(response).to have_http_status(:conflict)
      end

      it 'returns an error message' do
        expect(response.parsed_body).to have_key('error')
      end
    end

    context 'when the balance is below the order amount' do
      let(:order) { create(:order, user: user, amount_cents: 50_000) }

      before { complete_request }

      it 'responds 422 Unprocessable' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'leaves the order created' do
        expect(order.reload).to be_created
      end
    end

    context 'when the order does not exist' do
      let(:target_id) { 0 }

      before { complete_request }

      it 'responds 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when a database lock times out under contention' do
      before do
        allow(Orders::Complete).to receive(:call).and_raise(ActiveRecord::LockWaitTimeout)
        complete_request
      end

      it 'responds 503 Service Unavailable' do
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'asks the client to retry later' do
        expect(response.headers['Retry-After']).to eq('5')
      end
    end
  end
end
