# frozen_string_literal: true

require "test_helper"

class ForumCategoriesControllerTest < ActionDispatch::IntegrationTest
  context "The forum categories controller" do
    setup do
      @user = create(:user)
      @admin = create(:admin_user)
      as(@admin) do
        @category = ForumCategory.find_by(id: FemboyFans.config.alias_implication_forum_category) || create(:forum_category)
        @category2 = create(:forum_category, can_view: User::Levels::ADMIN, can_create: User::Levels::ADMIN)
      end
    end

    context "show action" do
      should "render" do
        get forum_category_path(@category)
        assert_redirected_to(forum_topics_path(search: { category_id: @category.id }))
      end

      should "restrict access" do
        assert_access(User::Levels::ANONYMOUS, success_response: :redirect, anonymous_response: :redirect) { |user| get_auth forum_category_path(@category), user }
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| get_auth forum_category_path(@category2), user }
      end
    end

    context "index action" do
      should "render" do
        get forum_categories_path
        assert_response :success
      end

      should "only list visible categories" do
        get forum_categories_path(format: :json)
        assert_response :success
        assert_equal([@category.id], @response.parsed_body.pluck("id"))
      end

      should "restrict access" do
        assert_access(User::Levels::ANONYMOUS) { |user| get_auth forum_categories_path, user }
      end
    end

    context "edit action" do
      should "work" do
        get_auth edit_forum_category_path(@category), @admin
        assert_response :success
      end

      should "restrict access" do
        assert_access(User::Levels::ADMIN) { |user| get_auth edit_forum_category_path(@category), user }
      end
    end

    context "update action" do
      should "work" do
        put_auth forum_category_path(@category), @admin, params: { forum_category: { name: "foobar" } }
        assert_redirected_to(forum_categories_path)
        assert_equal("foobar", @category.reload.name)
      end

      should "restrict access" do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| put_auth forum_category_path(@category), user, params: { name: SecureRandom.hex(6) } }
      end
    end

    context "new action" do
      should "work" do
        get_auth new_forum_category_path, @admin
        assert_response :success
      end

      should "restrict access" do
        assert_access(User::Levels::ADMIN) { |user| get_auth new_forum_category_path, user }
      end
    end

    context "create action" do
      should "work" do
        assert_difference("ForumCategory.count", 1) do
          post_auth forum_categories_path, @admin, params: { forum_category: { name: "foobar" } }
          assert_redirected_to(forum_categories_path)
          assert_equal("foobar", ForumCategory.last.name)
        end
      end

      should "restrict access" do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| post_auth forum_categories_path, user, params: { name: SecureRandom.hex(6) } }
      end
    end

    context "destroy action" do
      context "with no topics" do
        should "work" do
          assert_difference("ForumCategory.count", -1) do
            delete_auth forum_category_path(@category), @admin
            assert_redirected_to(forum_categories_path)
          end
        end

        should "restrict access" do
          @categories = as(@admin) { create_list(:forum_category, User::Levels.constants.length) }
          assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| delete_auth forum_category_path(@categories.shift), user }
        end
      end

      context "with topics" do
        setup do
          as(@admin) do
            @topic = create(:forum_topic, category: @category)
          end
        end

        should "fail" do
          assert_no_difference(%w[ForumCategory.count ForumTopic.count]) do
            delete_auth forum_category_path(@category), @admin, params: { format: :json }
            assert_response :unprocessable_entity
            assert_equal(["Forum category cannot be deleted because it has topics"], @response.parsed_body.dig("errors", "base"))
          end
        end
      end
    end

    context "move_all_topics action" do
      setup do
        as(@admin) do
          @category3 = create(:forum_category)
          @category4 = create(:forum_category)
          @topic = create(:forum_topic, category: @category3)
        end
      end

      should "work" do
        assert_equal(@category3.id, @topic.category_id)
        assert_difference({ "@category3.forum_topics.count" => -1, "@category4.forum_topics.count" => 1 }) do
          post_auth move_all_topics_forum_category_path(@category3), @admin, params: { forum_category: { new_category_id: @category4.id } }
          assert_redirected_to(forum_categories_path)
          perform_enqueued_jobs(only: MoveForumCategoryTopicsJob)
          assert_equal(@category4.id, @topic.reload.category_id)
        end
      end

      should "fail if the category has too many topics" do
        stub_const(ForumCategory, :MAX_TOPIC_MOVE_COUNT, 0) do
          assert_no_difference(%w[@category3.forum_topics.count @category4.forum_topics.count]) do
            post_auth move_all_topics_forum_category_path(@category3), @admin, params: { forum_category: { new_category_id: @category4.id } }
            assert_response :bad_request
          end
        end
      end

      should "restrict access" do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| post_auth move_all_topics_forum_category_path(@category3), user, params: { forum_category: { new_category_id: @category4.id } } }
      end
    end
  end
end
