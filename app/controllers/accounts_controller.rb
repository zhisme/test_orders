# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :find_account

  def show
    render json: serialize(account)
  end

  def deposit
    Accounts::Deposit.call(account, deposit_params[:amount_cents])
    render json: serialize(account)
  end

  private

  attr_reader :account

  def find_account
    @account = Account.find(params.expect(:id))
  end

  def deposit_params
    params.expect(deposit: [:amount_cents])
  end

  def serialize(account)
    {
      id: account.id,
      user_id: account.user_id,
      balance_cents: account.balance_cents
    }
  end
end
