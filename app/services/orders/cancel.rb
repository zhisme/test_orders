# frozen_string_literal: true

module Orders
  class Cancel < ApplicationService
    def initialize(order)
      super()
      @order = order
    end

    def call
      ensure_cancellable!

      ActiveRecord::Base.transaction do
        account = order.account.lock!
        refund!(account)
        order.cancelled!
      end

      order
    end

    private

    attr_reader :order

    def ensure_cancellable!
      raise Errors::Conflict, "order #{order.id} already cancelled" if order.cancelled?
      raise Errors::InvalidTransition, "order #{order.id} not in success state" unless order.success?
    end

    def refund!(account)
      charge = account.account_transactions.charge.find_by!(order: order)
      account.account_transactions.create!(
        order: order,
        amount_cents: -charge.amount_cents,
        kind: :refund
      )
    end
  end
end
