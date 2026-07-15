# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Deposit do
  subject(:deposit) { described_class.call(account, amount_cents) }

  let(:account) { create(:account) }

  context 'with a positive amount' do
    let(:amount_cents) { 5_000 }

    it 'raises the balance by the amount' do
      expect { deposit }.to change(account, :balance_cents).by(5_000)
    end

    it 'posts one deposit entry' do
      deposit
      expect(account.account_transactions.deposit.count).to eq(1)
    end
  end

  shared_examples 'a rejected deposit' do
    it 'raises InvalidAmount' do
      expect { deposit }.to raise_error(Accounts::Errors::InvalidAmount)
    end

    it 'posts no transaction' do
      expect { deposit }.to raise_error(Accounts::Errors::InvalidAmount)
      expect(account.account_transactions.count).to eq(0)
    end
  end

  context 'with a zero amount' do
    let(:amount_cents) { 0 }

    it_behaves_like 'a rejected deposit'
  end

  context 'with a negative amount' do
    let(:amount_cents) { -100 }

    it_behaves_like 'a rejected deposit'
  end
end
