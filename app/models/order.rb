# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user

  enum :status, { created: 'created', success: 'success', cancelled: 'cancelled' }

  validates :amount_cents, numericality: { greater_than: 0 }

  delegate :account, to: :user
end
