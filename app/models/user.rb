# frozen_string_literal: true

class User < ApplicationRecord
  has_one :account, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :name, presence: true
end
