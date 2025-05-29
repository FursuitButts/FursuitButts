# frozen_string_literal: true

module Users
  class MFAController < ApplicationController
    respond_to(:html, :json)

    rescue_from(User::MFAError, with: ->(err) { render_expected_error(400, err.message) })

    before_action(:requires_reauthentication)

    def edit
      @user = authorize(CurrentUser.user, policy_class: MFAPolicy)
      @mfa = @user.mfa || ::MFA.new(username: @user.name)
      respond_with(@mfa)
    end

    def update
      @user = authorize(CurrentUser.user, policy_class: MFAPolicy)
      @mfa = ::MFA.from_signed_secret(params.dig(:mfa, :signed_secret))
      if @mfa.verify(params.dig(:mfa, :verification_code))
        @user.update_mfa_secret!(@mfa.secret, request)
        notice("Two-factor authentication enabled")
      else
        @mfa.errors.add(:verification_code, "is incorrect")
      end

      respond_with(@mfa, location: user_mfa_backup_codes_path)
    end

    def destroy
      @user = authorize(CurrentUser.user, policy_class: MFAPolicy)
      @user.update_mfa_secret!(nil, request)
      notice("Two-factor authentication disabled")
      respond_with(@mfa, location: edit_users_path)
    end
  end
end
