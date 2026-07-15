# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::Cancel do
  subject(:cancel) { described_class.call(order) }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:order) { create(:order, user: user, amount_cents: 1_000) }

  before { Accounts::Deposit.call(account, 10_000) }

  context 'when the order is success' do
    before { Orders::Complete.call(order) }

    it 'transitions the order to cancelled' do
      expect { cancel }.to change(order, :status).from('success').to('cancelled')
    end

    it 'refunds the charge amount' do
      expect { cancel }.to change(account, :balance_cents).by(1_000)
    end

    it 'restores the original balance' do
      cancel
      expect(account.balance_cents).to eq(10_000)
    end

    it 'posts one refund for the order' do
      cancel
      expect(account.account_transactions.refund.where(order: order).count).to eq(1)
    end
  end

  context 'when the order is still created' do
    it 'raises InvalidTransition' do
      expect { cancel }.to raise_error(Orders::Errors::InvalidTransition)
    end

    it 'posts no refund' do
      expect { cancel }.to raise_error(Orders::Errors::InvalidTransition)
      expect(account.account_transactions.refund.count).to eq(0)
    end
  end

  context 'when the order is already cancelled' do
    before do
      Orders::Complete.call(order)
      described_class.call(order)
    end

    it 'raises Conflict' do
      expect { cancel }.to raise_error(Orders::Errors::Conflict)
    end

    it 'does not post another transaction' do
      count = account.account_transactions.count

      expect { cancel }.to raise_error(Orders::Errors::Conflict)
      expect(account.account_transactions.count).to eq(count)
    end
  end
end
