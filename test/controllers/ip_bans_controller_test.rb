# frozen_string_literal: true

require("test_helper")

class IpBansControllerTest < ActionDispatch::IntegrationTest
  context("The ip bans controller") do
    setup do
      @admin = create(:admin_user)
    end

    context("new action") do
      should("render") do
        get_auth(new_ip_ban_path, @admin)
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN) { |user| get_auth(new_ip_ban_path, user) }
      end
    end

    context("create action") do
      should("work") do
        assert_difference("IpBan.count", 1) do
          post_auth(ip_bans_path, @admin, params: { ip_ban: { ip_addr: "1.2.3.4", reason: "xyz" } })
        end
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| post_auth(ip_bans_path, user, params: { ip_ban: { ip_addr: "100.#{rand(0..255)}.#{rand(0..255)}.#{rand(0..255)}", reason: "xyz" } }) }
      end
    end

    context("index action") do
      setup do
        create(:ip_ban, ip_addr: "1.2.3.4")
      end

      should("render") do
        get_auth(ip_bans_path, @admin)
        assert_response(:success)
      end

      should("render with search parameters") do
        get_auth(ip_bans_path, @admin, params: { search: { ip_addr: "1.2.3.4" } })
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN) { |user| get_auth(ip_bans_path, user) }
      end
    end

    context("destroy action") do
      setup do
        @ip_ban = create(:ip_ban, ip_addr: "1.2.3.4")
      end

      should("work") do
        assert_difference("IpBan.count", -1) do
          delete_auth(ip_ban_path(@ip_ban), @admin, params: { format: "js" })
        end
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| delete_auth(ip_ban_path(create(:ip_ban, ip_addr: "100.#{rand(0..255)}.#{rand(0..255)}.#{rand(0..255)}")), user) }
      end
    end
  end
end
