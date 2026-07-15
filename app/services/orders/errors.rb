# frozen_string_literal: true

module Orders
  module Errors
    class InvalidTransition < StandardError; end
    class Conflict < StandardError; end
    class InsufficientFunds < StandardError; end
  end
end
