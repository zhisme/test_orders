# frozen_string_literal: true

module Orders
  class Complete < ApplicationService
    def initialize(order)
      super()
      @order = order
    end

    def call
      ActiveRecord::Base.transaction do
        order.lock!
        ensure_completable!
        account = order.account.lock!
        ensure_sufficient_funds!(account)
        charge!(account)
        order.success!
      end

      order
    end

    private

    attr_reader :order

    def ensure_completable!
      raise Errors::Conflict, "order #{order.id} already completed" if order.success?
      raise Errors::InvalidTransition, "order #{order.id} not in created state" unless order.created?
    end

    def ensure_sufficient_funds!(account)
      return if account.balance_cents >= order.amount_cents

      raise Errors::InsufficientFunds,
            "account #{account.id} balance #{account.balance_cents} below order #{order.id}"
    end

    def charge!(account)
      account.account_transactions.create!(
        order: order,
        amount_cents: -order.amount_cents,
        kind: :charge
      )
    end
  end
end
