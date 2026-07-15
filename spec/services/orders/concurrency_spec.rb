# frozen_string_literal: true

require 'rails_helper'

# Real-thread races need committed data visible across connections, so this
# group opts out of transactional fixtures and cleans up by hand.
RSpec.describe 'Orders concurrency', type: :model do
  self.use_transactional_tests = false

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let!(:order) { create(:order, user: user, amount_cents: 1_000) }

  before { Accounts::Deposit.call(account, 10_000) }

  after do
    AccountTransaction.delete_all
    Order.delete_all
    Account.delete_all
    User.delete_all
  end

  # Runs the block in two threads released simultaneously, returns their
  # outcomes (:ok or the raised exception class).
  def race(&)
    barrier = Concurrent::CyclicBarrier.new(2)
    outcomes = Queue.new

    threads = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          barrier.wait
          begin
            yield
            outcomes << :ok
          rescue StandardError => e
            outcomes << e.class
          end
        end
      end
    end
    threads.each(&:join)

    Array.new(outcomes.size) { outcomes.pop }
  end

  describe 'completing the same order twice at once' do
    it 'charges the account exactly once' do
      race { Orders::Complete.call(Order.find(order.id)) }

      expect(account.account_transactions.charge.where(order: order).count).to eq(1)
    end

    it 'debits the balance only once' do
      race { Orders::Complete.call(Order.find(order.id)) }

      expect(account.balance_cents).to eq(9_000)
    end

    it 'lets one thread win and the other conflict' do
      outcomes = race { Orders::Complete.call(Order.find(order.id)) }

      expect(outcomes).to contain_exactly(:ok, Orders::Errors::Conflict)
    end
  end

  describe 'cancelling the same order twice at once' do
    before { Orders::Complete.call(order) }

    it 'refunds the account exactly once' do
      race { Orders::Cancel.call(Order.find(order.id)) }

      expect(account.account_transactions.refund.where(order: order).count).to eq(1)
    end

    it 'restores the balance only once' do
      race { Orders::Cancel.call(Order.find(order.id)) }

      expect(account.balance_cents).to eq(10_000)
    end
  end
end
