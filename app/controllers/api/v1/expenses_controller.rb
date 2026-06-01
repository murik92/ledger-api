class Api::V1::ExpensesController < ApplicationController
  before_action :authenticate_request

  def create
    transaction =
      Transactions::CreateExpenseTransactionService.call(
        user: current_user,
        wallet: Wallet.find(
        expense_params[:wallet_id]
        ),
        category: Category.find(
        expense_params[:category_id]
        ),
        amount_cents: expense_params[:amount_cents].to_i,
        note: expense_params[:note]
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

  def expense_params
    params.permit(
      :wallet_id,
      :category_id,
      :amount_cents,
      :note
    )
  end
end
