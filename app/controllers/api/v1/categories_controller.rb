# app/controllers/api/v1/categories_controller.rb

class Api::V1::CategoriesController < ApplicationController
  before_action :authenticate_request

  def index
    categories =
      current_user.categories.order(:name)

    render json: {
      status: "success",
      data: categories
    }
  end

  def create
    category =
      Category::CreateCategoryService.call(
        user: current_user,
        name: category_params[:name],
        category_type: category_params[:category_type]
      )

    render json: {
      status: "success",
      data: category
    }, status: :created
  end

  private

  def category_params
    params.require(:category)
          .permit(
            :name,
            :category_type
          )
  end
end
