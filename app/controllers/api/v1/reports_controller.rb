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
    render json: {
      message: "not implemented yet"
    }
  end

  def by_category
    render json: {
      message: "not implemented yet"
    }
  end
end
