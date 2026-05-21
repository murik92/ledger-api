class Api::V1::TransfersController < ApplicationController
  before_action :authenticate_request

  def create
    from_account =
      current_user.accounts.find(
        params[:from_account_id]
      )

    to_account =
      Account.find(
        params[:to_account_id]
      )

    transaction = TransferService.call(
      from: from_account,
      to: to_account,
      amount_cents:
        params[:amount_cents].to_i,
      reference:
        "api-transfer-#{SecureRandom.uuid}",
      idempotency_key:
        params[:idempotency_key]
    )

    render json: {
      status: "success",
      transaction: {
        id: transaction.id,
        reference: transaction.reference,
        status: transaction.status
      }
    }, status: :created

  rescue BadRequestError => e
    render json: {
      status: "error",
      message: e.message
    }, status: :bad_request

  rescue StandardError => e
    render json: {
      status: "error",
      message: e.message
    }, status: :unprocessable_content
  end
end