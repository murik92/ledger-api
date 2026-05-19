class Api::V1::TransfersController < ApplicationController
  def create
    from_account =
      Account.find(params[:from_account_id])

    to_account =
      Account.find(params[:to_account_id])

    idempotency_key =
      request.headers["Idempotency-Key"]

    if idempotency_key.blank?
      return render json: {
        error: "Idempotency-Key header required"
      }, status: :bad_request
    end

    transaction = TransferService.call(
      from: from_account,
      to: to_account,
      amount_cents: params[:amount_cents].to_i,
      reference: params[:reference],
      idempotency_key: idempotency_key
    )

    render json: {
      status: "success",
      transaction_id: transaction.id
    }, status: :created

  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Account not found"
    }, status: :not_found

  rescue => e
    render json: {
      error: e.message
    }, status: :unprocessable_entity
  end
end
