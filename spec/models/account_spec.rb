# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  subject(:account) { create(:account) }

  describe '#balance_cents' do
    context 'without any transactions' do
      it 'is zero' do
        expect(account.balance_cents).to eq(0)
      end
    end

    context 'with charge and refund entries' do
      before do
        account.account_transactions.create!(amount_cents: -700, kind: :charge)
        account.account_transactions.create!(amount_cents: 200, kind: :refund)
      end

      it 'sums the entry amounts' do
        expect(account.balance_cents).to eq(-500)
      end
    end
  end
end
