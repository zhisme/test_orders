# frozen_string_literal: true

2.times do |i|
  user = User.create!(name: "user#{i + 1}")
  account = Account.create!(user: user)
  Accounts::Deposit.call(account, 10_000)
end

puts "All seeded. Proceed with testing!"
