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
          as(@user) do
            @note = create(:note)
          end
          @user2 = create(:user)

          as(@user2, "1.2.3.4") do
            @note.update(body: "1 2")
          end

          as(@user, "1.2.3.4") do
            @note.update(body: "1 2 3")
          end
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
