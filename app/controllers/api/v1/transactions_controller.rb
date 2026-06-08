class Api::V1::TransactionsController < ApplicationController
  before_action :authenticate_request

  def index
    transactions =
      CategorizedTransaction
        .includes(:category)
        .where(user: current_user)
        .order(created_at: :desc)

    render json: {
      status: "success",
      data: transactions.map { |transaction|
        {
          id: transaction.id,
          transaction_type: transaction.transaction_type,
          category: transaction.category.name,
          note: transaction.note,
          created_at: transaction.created_at
        }
      }
    }
  end
end
