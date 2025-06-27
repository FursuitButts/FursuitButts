# frozen_string_literal: true

require("test_helper")

class UploadWhitelistTest < ActiveSupport::TestCase
  context("A upload whitelist") do
    setup do
      @user = create(:trusted_user)

      @whitelist = create(:upload_whitelist, pattern: "*.#{FemboyFans.config.domain}/*", note: "local")
    end

    should("match") do
      assert_equal([true, nil], UploadWhitelist.is_whitelisted?(Addressable::URI.parse("https://#{FemboyFans.config.cdn_domain}/123.png"), @user))
      assert_equal([false, "123.com not in whitelist"], UploadWhitelist.is_whitelisted?(Addressable::URI.parse("https://123.com/what.png"), @user))
    end

    should("bypass for admins") do
      @user.update_columns(level: User::Levels::ADMIN)
      assert_equal([true, "bypassed"], UploadWhitelist.is_whitelisted?(Addressable::URI.parse("https://123.com/what.png"), @user))
    end
  end
end
