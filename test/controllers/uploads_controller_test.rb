# frozen_string_literal: true

require("test_helper")

class UploadsControllerTest < ActionDispatch::IntegrationTest
  context("The uploads controller") do
    setup do
      @user = create(:janitor_user)
    end

    context("new action") do
      should("render") do
        get_auth(new_upload_path, @user)
        assert_response(:success)
      end

      context("when uploads are disabled") do
        setup do
          Security::Lockdown.uploads_min_level = User::Levels::TRUSTED
        end

        teardown do
          Security::Lockdown.uploads_min_level = User::Levels::MEMBER
        end

        should("prevent uploads") do
          get_auth(new_upload_path, create(:user))
          assert_response(:forbidden)
        end

        should("allow uploads for users of the same or higher level") do
          get_auth(new_upload_path, create(:trusted_user, created_at: 2.weeks.ago))
          assert_response(:success)
        end
      end

      should("restrict access") do
        FemboyFans.config.stubs(:disable_age_checks?).returns(true)
        assert_access(User::Levels::MEMBER) { |user| get_auth(new_upload_path, user) }
      end
    end

    context("index action") do
      setup do
        @upload = create(:upload, tag_string: "foo bar")
      end

      should("render") do
        get_auth(uploads_path, @user)
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::JANITOR) { |user| get_auth(uploads_path, user) }
      end
    end

    context("show action") do
      setup do
        @pending = create(:upload)
        @upload = create(:jpg_upload)
      end

      should("render") do
        get_auth(upload_path(@pending), @user)
        assert_response(:success)
      end

      should("redirect if post exists") do
        get_auth(upload_path(@upload), @user)
        assert_redirected_to(post_path(@upload.post))
      end

      should("restrict access") do
        assert_access(User::Levels::JANITOR) { |user| get_auth(upload_path(@pending), user) }
      end
    end

    context("create action") do
      should("create a new upload") do
        assert_difference("Upload.count", 1) do
          file = fixture_file_upload("test.jpg")
          post_auth(uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" }, format: :json })
          assert_response(:success)
        end
      end

      should("autoapprove uploads by approvers") do
        assert_difference("Upload.count", 1) do
          file = fixture_file_upload("test.jpg")
          post_auth(uploads_path, create(:janitor_user), params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" }, format: :json })
          assert_response(:success)
        end
        assert_equal(false, Post.last.is_pending?)
        assert_equal(false, @user.notifications.post_approve.exists?)
      end

      context("with a previously destroyed post") do
        setup do
          @admin = create(:admin_user)
          @upload = create(:jpg_upload)
          @upload.media_asset.expunge!(@admin)
        end

        should("fail and create ticket") do
          assert_difference({ "Post.count" => 0, "Ticket.count" => 1 }) do
            assert_enqueued_jobs(1, only: NotifyExpungedMediaAssetReuploadJob) do
              file = fixture_file_upload("test.jpg")
              post_auth(uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" }, format: :json })
              assert_response(:precondition_failed)
              assert_equal("That image has been deleted and cannot be reuploaded", @response.parsed_body["message"])
              assert_equal("expunged", UploadMediaAsset.last.status)
            end
            perform_enqueued_jobs(only: NotifyExpungedMediaAssetReuploadJob)
          end
        end

        # TODO
        # should "fail and not create ticket if notify=false" do
        #   DestroyedPost.find_by!(post_id: @post.id).update_column(:notify, false)
        #   assert_difference(%w[Post.count Ticket.count], 0) do
        #     file = fixture_file_upload("test.jpg")
        #     post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
        #   end
        # end
      end

      should("restrict access") do
        file = fixture_file_upload("test.jpg")
        FemboyFans.config.stubs(:disable_age_checks?).returns(true)
        assert_access(User::Levels::MEMBER, anonymous_response: :forbidden) do |user|
          [Upload, PostVersion, Post, UploadMediaAsset].each(&:delete_all)
          post_auth(uploads_path, user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" }, format: :json })
        end
      end
    end
  end
end
