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

  def update
    category =
        current_user.categories.find(
        params[:id]
        )

    updated_category =
        Category::UpdateCategoryService.call(
        category: category,
        user: current_user,
        name: category_params[:name],
        category_type: category_params[:category_type]
        )

    render json: {
        status: "success",
        data: updated_category
    }
    end

    def destroy
        category =
            current_user.categories.find(
            params[:id]
            )

        Category::DeleteCategoryService.call(
            category: category,
            user: current_user
        )

        render json: {
            status: "success",
            message: "Category deleted"
        }, status: :ok
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
