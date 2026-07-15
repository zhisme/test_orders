# frozen_string_literal: true

class AccountTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :order, optional: true

  enum :kind, { charge: 'charge', refund: 'refund', deposit: 'deposit' }

  validates :amount_cents, presence: true
end
