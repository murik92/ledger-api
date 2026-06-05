class UserMailer < ApplicationMailer
  def confirmation_email(user)
    @user = user

    # URL for email confirmation
    @confirmation_url =
      "http://localhost:3000/api/v1/auth/confirm?token=#{@user.confirmation_token}"

    mail(
      to: @user.email,
      subject: "Confirm your email"
    )
  end

  def password_reset_email(user)
    @user = user

    # URL for password reset
    
    @reset_password_url =
      "http://localhost:3000/api/v1/auth/reset_password?token=#{@user.reset_password_token}"

    mail(
      to: @user.email,
      subject: "Reset your password"
    )
  end
end
