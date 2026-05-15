class Api::V1::TransfersController < ApplicationController
  def create
    from_account = Account.find(params[:from_account_id])
    to_account = Account.find(params[:to_account_id])

    idempotency_key = request.headers["Idempotency-Key"]

    transaction = TransferService.call(
      from: from_account,
      to: to_account,
      amount_cents: params[:amount_cents],
      reference: idempotency_key
    )

    render json: {
      status: "success",
      transaction_id: transaction.id
    }, status: :created

  rescue => e
    render json: {
      error: e.message
    }, status: :unprocessable_entity
  end
end