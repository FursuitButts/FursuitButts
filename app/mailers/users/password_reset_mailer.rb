# frozen_string_literal: true

module Users
  class PasswordResetMailer < ApplicationMailer
    default(from: FemboyFans.config.mail_from_addr, content_type: "text/html")

    def reset_request(user, nonce)
      @user = user
      @nonce = nonce
      mail(to: @user.email, subject: "#{FemboyFans.config.app_name} password reset")
    end
  end
end
