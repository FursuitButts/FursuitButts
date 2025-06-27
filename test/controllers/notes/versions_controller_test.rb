# frozen_string_literal: true

require("test_helper")

module Notes
  class VersionsControllerTest < ActionDispatch::IntegrationTest
    context("The note versions controller") do
      setup do
        @user = create(:user)
      end

      context("index action") do
        setup do
          @note = create(:note, creator: @user)
          @user2 = create(:user)

          @note.update_with(@user2, body: "1 2")

          @note.update_with(@user, body: "1 2 3")
        end

        should("list all versions") do
          get(note_versions_path)
          assert_response(:success)
        end

        should("list all versions that match the search criteria") do
          get(note_versions_path, params: { search: { updater_id: @user2.id } })
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(note_versions_path, user) }
        end
      end
    end
  end
end
