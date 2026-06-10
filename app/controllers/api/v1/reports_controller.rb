class Api::V1::ReportsController < ApplicationController
  before_action :authenticate_request

  def monthly
    month =
      params[:month] ||
      Date.current.strftime("%Y-%m")

    report =
      Reports::MonthlyReportService.call(
        user: current_user,
        month: month
      )

    render json: {
      status: "success",
      data: report
    }
  end

  def cashflow
    report =
      Reports::CashflowReportService.call(
        user: current_user,
        from: parsed_from_date,
        to: parsed_to_date
      )

    render json: {
      status: "success",
      data: report
    }
  end

  def by_category
    report =
      Reports::CategoryReportService.call(
        user: current_user,
        from: parsed_from_date,
        to: parsed_to_date,
        transaction_type: transaction_type
      )

    render json: {
      status: "success",
      data: report
    }
  end

  private

  def parsed_from_date
    params[:from]&.to_date ||
      Date.current.beginning_of_month
  end

  def parsed_to_date
    params[:to]&.to_date ||
      Date.current.end_of_month
  end

  def transaction_type
    params[:transaction_type] || "expense"
  end
end
