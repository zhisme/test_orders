# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  subject(:complete_request) { post complete_order_path(id: target_id) }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:order) { create(:order, user: user, amount_cents: 1_000) }
  let(:target_id) { order.id }

  before { Accounts::Deposit.call(account, 10_000) }

  describe 'POST /orders' do
    let(:params) { { order: { user_id: user.id, amount_cents: 1_000 } } }

    it 'creates an order' do
      expect { post orders_path, params: params }.to change(Order, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    context 'with an Idempotency-Key' do
      let(:headers) { { 'Idempotency-Key' => 'abc-123' } }

      it 'creates only one order across repeated requests' do
        post orders_path, params: params, headers: headers
        first_id = response.parsed_body['id']

        expect { post orders_path, params: params, headers: headers }
          .not_to change(Order, :count)
        expect(response).to have_http_status(:created)
        expect(response.parsed_body['id']).to eq(first_id)
      end

      it 'scopes uniqueness to the key, not the payload' do
        post orders_path, params: params, headers: headers
        first_id = response.parsed_body['id']

        # Different amount, same key -> still the original order, no new row
        post orders_path,
             params: { order: { user_id: user.id, amount_cents: 9_999 } },
             headers: headers

        expect(response.parsed_body['id']).to eq(first_id)
        expect(Order.find(first_id).amount_cents).to eq(1_000)
      end
    end

    it 'allows distinct orders when no key is sent' do
      post orders_path, params: params
      expect { post orders_path, params: params }.to change(Order, :count).by(1)
    end
  end

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
