class Api::V1::IncomesController < ApplicationController
  before_action :authenticate_request

  def create
  wallet =
    Wallet.find(
      income_params[:wallet_id]
    )

  category =
    Category.find(
      income_params[:category_id]
    )

  transaction =
    Transactions::CreateIncomeTransactionService.call(
      user: current_user,
      wallet: wallet,
      category: category,
      amount_cents: income_params[:amount_cents].to_i,
      note: income_params[:note]
    )

  render json: {
    success: true,
    transaction_id: transaction.id
  }, status: :created

  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  private

  def income_params
    params.permit(
      :wallet_id,
      :category_id,
      :amount_cents,
      :note
    )
  end
end
