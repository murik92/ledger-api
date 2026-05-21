class Api::V1::AccountsController < ApplicationController

  before_action :authenticate_request

  def create
    account = current_user.accounts.create!(
      account_params.merge(
        balance_cents: 0,
        opening_balance_cents: 0
      )
    )

    render json: {
      status: "success",
      account: {
        id: account.id,
        name: account.name,
        currency: account.currency,
        balance_cents: account.balance_cents,
        user_id: account.user_id
      }
    }, status: :created
  end

  def index
    accounts = current_user.accounts

    render json: {
      status: "success",
      accounts: accounts.map do |account|
        {
          id: account.id,
          name: account.name,
          currency: account.currency,
          balance_cents: account.balance_cents
        }
      end
    }
  end

  def show
    account = current_user.accounts.find(params[:id])

    render json: {
      status: "success",
      account: {
        id: account.id,
        name: account.name,
        currency: account.currency,
        balance_cents: account.balance_cents
      }
    }
  end
  
  def deposit
  account = current_user.accounts.find(params[:id])

  amount = params[:amount_cents].to_i

  if amount <= 0
    return render json: {
      status: "error",
      message: "Amount must be greater than 0"
    }, status: :unprocessable_entity
  end

  ApplicationRecord.transaction do
    account.update!(
      balance_cents: account.balance_cents + amount
    )
  end

  render json: {
     status: "success",
     account: {
       id: account.id,
       name: account.name,
       currency: account.currency,
       balance_cents: account.balance_cents
      }
    }
  end

  private

  def account_params
    params.require(:account).permit(
      :name,
      :currency
    )
  end
end