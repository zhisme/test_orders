# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::Complete do
  subject(:complete) { described_class.call(order) }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:order) { create(:order, user: user, amount_cents: 1_000) }

  before { Accounts::Deposit.call(account, 10_000) }

  context 'when the order is created and the balance covers it' do
    it 'transitions the order to success' do
      expect { complete }.to change(order, :status).from('created').to('success')
    end

    it 'debits the account by the order amount' do
      expect { complete }.to change(account, :balance_cents).by(-1_000)
    end

    it 'posts exactly one charge for the order' do
      complete
      expect(account.account_transactions.charge.where(order: order).count).to eq(1)
    end
  end

  context 'when the order is already success' do
    before { described_class.call(order) }

    it 'raises Conflict' do
      expect { complete }.to raise_error(Orders::Errors::Conflict)
    end

    it 'does not post another transaction' do
      count = account.account_transactions.count

      expect { complete }.to raise_error(Orders::Errors::Conflict)
      expect(account.account_transactions.count).to eq(count)
    end
  end

  context 'when the order is cancelled' do
    before { order.update!(status: :cancelled) }

    it 'raises InvalidTransition' do
      expect { complete }.to raise_error(Orders::Errors::InvalidTransition)
    end
  end

  context 'when the balance is below the order amount' do
    let(:order) { create(:order, user: user, amount_cents: 50_000) }

    it 'raises InsufficientFunds' do
      expect { complete }.to raise_error(Orders::Errors::InsufficientFunds)
    end

    it 'posts no charge' do
      expect { complete }.to raise_error(Orders::Errors::InsufficientFunds)
      expect(account.account_transactions.charge.count).to eq(0)
    end

    it 'leaves the order created' do
      expect { complete }.to raise_error(Orders::Errors::InsufficientFunds)
      expect(order.reload).to be_created
    end
  end
end
