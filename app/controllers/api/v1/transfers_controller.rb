class Api::V1::TransfersController < ApplicationController

  before_action :authenticate_request

  def create
    from_account = current_user.accounts.find(
      params[:from_account_id]
    )

    to_account = Account.find(
      params[:to_account_id]
    )

    amount = params[:amount_cents].to_i

    if amount <= 0
      return render json: {
        status: "error",
        message: "Amount must be greater than 0"
      }, status: :unprocessable_entity
    end

    if from_account.balance_cents < amount
      return render json: {
        status: "error",
        message: "Insufficient funds"
      }, status: :unprocessable_entity
    end

    ApplicationRecord.transaction do

      from_account.update!(
        balance_cents: from_account.balance_cents - amount
      )

      to_account.update!(
        balance_cents: to_account.balance_cents + amount
      )

    end

    render json: {
      status: "success",
      transfer: {
        from_account_id: from_account.id,
        to_account_id: to_account.id,
        amount_cents: amount
      }
    }
  end
end