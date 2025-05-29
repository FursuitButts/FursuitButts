# frozen_string_literal: true

require("test_helper")

class ModActionsControllerTest < ActionDispatch::IntegrationTest
  context("The mod actions controller") do
    setup do
      @admin = create(:admin_user)
      as(@admin) { @mod_action = create(:mod_action) }
    end

    context("index action") do
      should("render") do
        get(mod_actions_path)
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::ANONYMOUS) { |user| get_auth(mod_actions_path, user) }
      end
    end

    context("show action") do
      should("redirect") do
        get(mod_action_path(@mod_action))
        assert_redirected_to(mod_actions_path(search: { id: @mod_action.id }))
      end

      should("restrict access") do
        assert_access(User::Levels::ANONYMOUS, success_response: :redirect, anonymous_response: :redirect) { |user| get_auth(mod_action_path(@mod_action), user) }
      end
    end
  end
end
