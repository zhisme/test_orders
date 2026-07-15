# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :user
  has_many :account_transactions, dependent: :destroy

  def balance_cents
    account_transactions.sum(:amount_cents)
  end
end
