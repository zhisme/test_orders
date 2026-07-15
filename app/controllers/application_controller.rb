# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from Orders::Errors::InvalidTransition, with: :unprocessable
  rescue_from Orders::Errors::InsufficientFunds, with: :unprocessable
  rescue_from Accounts::Errors::InvalidAmount, with: :unprocessable
  rescue_from Orders::Errors::Conflict, with: :conflict
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::LockWaitTimeout, with: :service_unavailable
  rescue_from ActiveRecord::StatementTimeout, with: :service_unavailable
  rescue_from ActiveRecord::ConnectionTimeoutError, with: :service_unavailable

  RETRY_AFTER_SECONDS = 5

  private

  def unprocessable(error)
    render json: { error: error.message }, status: :unprocessable_content
  end

  def conflict(error)
    render json: { error: error.message }, status: :conflict
  end

  def not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def service_unavailable(_error)
    response.set_header('Retry-After', RETRY_AFTER_SECONDS.to_s)
    render json: { error: 'service is under heavy load, please try again later' },
           status: :service_unavailable
  end
end
