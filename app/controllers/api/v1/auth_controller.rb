class Api::V1::AuthController < ApplicationController

  def login
    user = User.find_by(
      email: auth_params[:email]
    )

    if user&.authenticate(auth_params[:password])

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
      }, status: :ok

    else

      render json: {
        status: "error",
        message: "Invalid email or password"
      }, status: :unauthorized

    end
  end

  private

  def auth_params
    params.require(:auth).permit(
      :email,
      :password
    )
  end
end