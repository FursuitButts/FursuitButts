# frozen_string_literal: true

require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  context "The uploads controller" do
    setup do
      @user = create(:janitor_user)
    end

    context "new action" do
      should "render" do
        get_auth new_upload_path, @user
        assert_response :success
      end

      context "with a url" do
        should "prefer the file" do
          get_auth new_upload_path, @user, params: { url: "https://raikou1.donmai.us/d3/4e/d34e4cf0a437a5d65f8e82b7bcd02606.jpg" }
          file = fixture_file_upload("test.jpg")
          assert_difference(-> { Post.count }) do
            post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "https://raikou1.donmai.us/d3/4e/d34e4cf0a437a5d65f8e82b7bcd02606.jpg" } }
          end
          post = Post.last
          assert_equal("ecef68c44edb8a0d6a3070b5f8e8ee76", post.md5)
        end
      end

      context "for a post that has already been uploaded" do
        setup do
          as(@user) do
            @post = create(:post, source: "https://google.com/aaa")
          end
        end

        should "initialize the post" do
          assert_difference(-> { Upload.count }, 0) do
            get_auth new_upload_path, @user, params: { url: "https://google.com/aaa" }
            assert_response :success
          end
        end
      end

      context "when uploads are disabled" do
        setup do
          Security::Lockdown.uploads_min_level = User::Levels::TRUSTED
        end

        teardown do
          Security::Lockdown.uploads_min_level = User::Levels::MEMBER
        end

        should "prevent uploads" do
          get_auth new_upload_path, create(:user)
          assert_response :forbidden
        end

        should "allow uploads for users of the same or higher level" do
          get_auth new_upload_path, create(:trusted_user, created_at: 2.weeks.ago)
          assert_response :success
        end
      end

      should "restrict access" do
        FemboyFans.config.stubs(:disable_age_checks?).returns(true)
        assert_access(User::Levels::MEMBER) { |user| get_auth new_upload_path, user }
      end
    end

    context "index action" do
      setup do
        as(@user) do
          @upload = create(:source_upload, tag_string: "foo bar")
        end
      end

      should "render" do
        get_auth uploads_path, @user
        assert_response :success
      end

      context "with search parameters" do
        should "render" do
          search_params = {
            uploader_name:   @upload.uploader_name,
            source_matches:  @upload.source,
            rating:          @upload.rating,
            has_post:        "yes",
            post_tags_match: @upload.tag_string,
            status:          @upload.status,
          }

          get_auth uploads_path, @user, params: { search: search_params }
          assert_response :success
        end
      end

      should "restrict access" do
        assert_access(User::Levels::JANITOR) { |user| get_auth uploads_path, user }
      end
    end

    context "show action" do
      setup do
        as(@user) do
          @upload = create(:jpg_upload)
        end
      end

      should "render" do
        get_auth upload_path(@upload), @user
        assert_response :success
      end

      context "with a previously destroyed post" do
        setup do
          @admin = create(:admin_user)
          @upload = UploadService.new(attributes_for(:jpg_upload).merge({ uploader: @user })).start!
          @post = @upload.post
          as(@admin) { @post.expunge! }
        end

        should "fail and create ticket" do
          assert_difference({ "Post.count" => 0, "Ticket.count" => 1 }) do
            file = fixture_file_upload("test.jpg")
            post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
          end
        end

        should "fail and not create ticket if notify=false" do
          DestroyedPost.find_by!(post_id: @post.id).update_column(:notify, false)
          assert_difference(%w[Post.count Ticket.count], 0) do
            file = fixture_file_upload("test.jpg")
            post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
          end
        end
      end

      should "restrict access" do
        assert_access(User::Levels::JANITOR) { |user| get_auth upload_path(@upload), user }
      end
    end

    context "create action" do
      should "create a new upload" do
        assert_difference("Upload.count", 1) do
          file = fixture_file_upload("test.jpg")
          post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
        end
      end

      should "autoapprove uploads by approvers" do
        assert_difference("Upload.count", 1) do
          file = fixture_file_upload("test.jpg")
          post_auth uploads_path, create(:janitor_user), params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
        end
        assert_equal(false, Post.last.is_pending?)
        assert_equal(false, @user.notifications.post_approve.exists?)
      end

      context "with a previously destroyed post" do
        setup do
          @admin = create(:admin_user)
          @upload = UploadService.new(attributes_for(:jpg_upload).merge({ uploader: @user })).start!
          @post = @upload.post
          as(@admin) { @post.expunge! }
        end

        should "fail and create ticket" do
          assert_difference({ "Post.count" => 0, "Ticket.count" => 1 }) do
            file = fixture_file_upload("test.jpg")
            post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
          end
        end

        should "fail and not create ticket if notify=false" do
          DestroyedPost.find_by!(post_id: @post.id).update_column(:notify, false)
          assert_difference(%w[Post.count Ticket.count], 0) do
            file = fixture_file_upload("test.jpg")
            post_auth uploads_path, @user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" } }
          end
        end
      end

      should "restrict access" do
        file = fixture_file_upload("test.jpg")
        FemboyFans.config.stubs(:disable_age_checks?).returns(true)
        assert_access(User::Levels::MEMBER, anonymous_response: :forbidden) do |user|
          Post.destroy_all
          post_auth uploads_path, user, params: { upload: { file: file, tag_string: "aaa", rating: "q", source: "aaa" }, format: :json }
        end
      end
    end
  end
end
