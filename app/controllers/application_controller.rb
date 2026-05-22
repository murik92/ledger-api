class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_internal_error

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]

    token = header.split(" ").last if header

    begin
      decoded = JsonWebToken.decode(token)

      @current_user =
        User.find(decoded["user_id"])

    rescue
      render json: {
        status: "error",
        message: "Unauthorized"
      }, status: :unauthorized
    end
  end

  def handle_internal_error(error)
    render json: {
      error: error.message
    }, status: :unprocessable_entity
  end
end
