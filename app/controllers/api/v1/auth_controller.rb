# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < ApplicationController
  # Только для logout нужен current_user через access token
  before_action :authenticate_request, only: [:logout]

  # =========================
  # LOGIN
  # =========================
  # POST /api/v1/auth/login
  def login
    user = User.find_by(email: auth_params[:email])

    if user&.authenticate(auth_params[:password])

      unless user.confirmed?
        return render json: {
          status: "error",
          message: "Email is not confirmed"
        }, status: :unauthorized
      end

      tokens = Auth::TokenIssuer.issue_tokens_for(user)

      render json: {
        status: "success",
        data: {
          user: {
            id: user.id,
            email: user.email
          },
          tokens: tokens
        }
      }, status: :ok

    else
      render json: {
        status: "error",
        message: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  # =========================
  # REFRESH
  # =========================
  # POST /api/v1/auth/refresh
  def refresh
    refresh_token = params[:refresh_token]

    if refresh_token.blank?
      return render json: {
        status: "error",
        message: "Refresh token missing"
      }, status: :unauthorized
    end

    begin
      user = user_from_refresh_token(refresh_token)
      tokens = Auth::TokenIssuer.rotate_refresh_token(user, refresh_token)

      render json: {
        status: "success",
        data: tokens
      }, status: :ok

    rescue ActiveRecord::RecordNotFound
      render json: {
        status: "error",
        message: "Invalid refresh token"
      }, status: :unauthorized

    rescue StandardError => e
      render json: {
        status: "error",
        message: e.message
      }, status: :unauthorized
    end
  end

  # =========================
  # LOGOUT
  # =========================
  # POST /api/v1/auth/logout
  def logout
    refresh_token = params[:refresh_token]

    if refresh_token.blank?
      return render json: {
        status: "error",
        message: "Refresh token missing"
      }, status: :unprocessable_content
    end

    Auth::TokenIssuer.revoke_refresh_token(current_user, refresh_token)

    render json: {
      status: "success",
      message: "Logged out successfully"
    }, status: :ok
  end

  # =========================
  # EMAIL CONFIRMATION
  # =========================
  # POST /api/v1/auth/confirm
  def confirm
    token = params[:token]

    if token.blank?
      return render json: {
        status: "error",
        message: "Confirmation token missing"
      }, status: :unprocessable_content
    end

    user = User.find_by(
      confirmation_token: token
    )

    unless user
      return render json: {
        status: "error",
        message: "Invalid confirmation token"
      }, status: :unprocessable_content
    end

    user.confirm!

    render json: {
      status: "success",
      message: "Email confirmed successfully"
    }, status: :ok
  end
  
  # =========================
  # PASSWORD RESET REQUEST
  # =========================
  # POST /api/v1/auth/password_reset
  def password_reset
    user = User.find_by(email: params[:email])

    unless user
      return render json: {
        status: "error",
        message: "User not found"
      }, status: :unprocessable_content
    end

    user.generate_password_reset_token

    render json: {
      status: "success",
      message: "Password reset token generated"
    }, status: :ok
  end

  # =========================
  # RESET PASSWORD
  # =========================
  # POST /api/v1/auth/reset_password
  def reset_password
    token = params[:token]

    user = User.find_by(
      reset_password_token: token
    )

    unless user
      return render json: {
        status: "error",
        message: "Invalid reset token"
      }, status: :unprocessable_content
    end

    if user.password_reset_token_expired?
      return render json: {
        status: "error",
        message: "Reset token expired"
      }, status: :unprocessable_content
    end

    if user.update(
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
      user.clear_password_reset_token

      render json: {
        status: "success",
        message: "Password updated successfully"
      }, status: :ok
    else
      render json: {
        status: "error",
        errors: user.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  # =========================
  # PRIVATE METHODS
  # =========================
  private

  def auth_params
    params.require(:auth).permit(:email, :password)
  end

  # Находит пользователя по refresh token (hash)
  def user_from_refresh_token(token)
    digest = Digest::SHA256.hexdigest(token)
    record = RefreshToken.find_by!(token_digest: digest)
    raise StandardError, "Refresh token revoked or expired" unless record.active?

    record.user
  end

  # Аутентификация по access token
  def authenticate_request
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last
    return render_unauthorized unless token

    decoded = JsonWebToken.decode(token)
    return render_unauthorized unless decoded && decoded[:type] == "access"

    @current_user = User.find_by(id: decoded[:user_id])
    render_unauthorized unless @current_user
  end

  def render_unauthorized
    render json: {
      status: "error",
      message: "Unauthorized"
    }, status: :unauthorized
  end

  # Для before_action
  attr_reader :current_user
end
