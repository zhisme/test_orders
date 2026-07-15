# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :find_order, only: %i[show complete cancel]

  def show
    render json: serialize(order)
  end

  def create
    order = Order.create!(order_params)
    render json: serialize(order), status: :created
  end

  def complete
    Orders::Complete.call(order)
    render json: serialize(order)
  end

  def cancel
    Orders::Cancel.call(order)
    render json: serialize(order)
  end

  private

  attr_reader :order

  def find_order
    @order = Order.find(params.expect(:id))
  end

  def order_params
    params.expect(order: %i[user_id amount_cents])
  end

  def serialize(order)
    {
      id: order.id,
      status: order.status,
      amount_cents: order.amount_cents,
      user_id: order.user_id
    }
  end
end
