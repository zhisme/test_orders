# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    user
    amount_cents { 1_000 }
    status { :created }
  end
end
