class Api::V1::TransactionsController < ApplicationController
  before_action :authenticate_request

  def index
    transactions =
      CategorizedTransaction
        .includes(:category)
        .where(user: current_user)

    if params[:transaction_type].present?
      transactions =
        transactions.where(
          transaction_type: params[:transaction_type]
        )
    end

    if params[:category_id].present?
      transactions =
        transactions.where(
          category_id: params[:category_id]
        )
    end

    if params[:date_from].present?
      transactions =
        transactions.where(
          "created_at >= ?",
          Date.parse(params[:date_from])
        )
    end

    if params[:date_to].present?
      transactions =
        transactions.where(
          "created_at <= ?",
          Date.parse(params[:date_to]).end_of_day
        )
    end

    transactions =
      transactions.order(created_at: :desc)

    # =========================
    # PAGINATION (TASK 41)
    # =========================

    page = params[:page].presence.to_i
    page = 1 if page <= 0

    per_page = params[:per_page].presence.to_i
    per_page = 20 if per_page <= 0
    per_page = 100 if per_page > 100

    total_count = transactions.count
    total_pages = (total_count.to_f / per_page).ceil

    transactions =
      transactions
        .offset((page - 1) * per_page)
        .limit(per_page)

    render json: {
      status: "success",
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      },
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

  def show
    transaction =
      CategorizedTransaction.find(params[:id])

    unless transaction.user == current_user
      return render json: {
        status: "error",
        message: "Access denied"
      }, status: :unprocessable_content
    end

    render json: {
      status: "success",
      data: {
        id: transaction.id,
        transaction_type: transaction.transaction_type,
        category: transaction.category.name,
        note: transaction.note,
        created_at: transaction.created_at,
        ledger_transaction_id: transaction.ledger_transaction_id
      }
    }
  end

  def create
    transaction =
      case transaction_params[:transaction_type]
      when "expense"
        Transactions::CreateExpenseTransactionService.call(
          user: current_user,
          wallet: Wallet.find(transaction_params[:wallet_id]),
          category: Category.find(transaction_params[:category_id]),
          amount_cents: transaction_params[:amount_cents].to_i,
          note: transaction_params[:note],
          idempotency_key: transaction_params[:idempotency_key]
        )

      when "income"
        Transactions::CreateIncomeTransactionService.call(
          user: current_user,
          wallet: Wallet.find(transaction_params[:wallet_id]),
          category: Category.find(transaction_params[:category_id]),
          amount_cents: transaction_params[:amount_cents].to_i,
          note: transaction_params[:note],
          idempotency_key: transaction_params[:idempotency_key]
        )

      else
        raise ArgumentError, "Invalid transaction type"
      end

    render json: {
      success: true,
      transaction_id: transaction.id
    }, status: :created

  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_content
  end

  private

  def transaction_params
    params.permit(
      :transaction_type,
      :wallet_id,
      :category_id,
      :amount_cents,
      :note,
      :idempotency_key
    )
  end
end
