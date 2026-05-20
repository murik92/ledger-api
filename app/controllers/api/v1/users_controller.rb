class Api::V1::UsersController < ApplicationController

  before_action :authenticate_request,
                only: [:profile]

  def create
    user = User.new(user_params)

    if user.save
      token = JsonWebToken.encode(
        user_id: user.id
      )

      render json: {
        status: "success",
        token: token,
        user: {
          id: user.id,
          email: user.email
        }
      }, status: :created

    else
      render json: {
        status: "error",
        errors: user.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  def profile
    render json: {
      status: "success",
      user: {
        id: current_user.id,
        email: current_user.email
      }
    }
  end

  private

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation
    )
  end
end
