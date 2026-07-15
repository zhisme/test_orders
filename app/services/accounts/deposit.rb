# frozen_string_literal: true

module Accounts
  class Deposit < ApplicationService
    def initialize(account, amount_cents)
      super()
      @account = account
      @amount_cents = amount_cents.to_i
    end

    def call
      raise Errors::InvalidAmount, "deposit amount #{amount_cents} must be positive" unless amount_cents.positive?

      account.account_transactions.create!(amount_cents: amount_cents, kind: :deposit)
      account
    end

    private

    attr_reader :account, :amount_cents
  end
end
