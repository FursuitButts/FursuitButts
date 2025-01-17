require 'test_helper'

class PostDisapprovalTest < ActiveSupport::TestCase
  context "In all cases" do
    setup do
      @alice = FactoryBot.create(:moderator_user, name: "alice")
      CurrentUser.user = @alice
      CurrentUser.ip_addr = "127.0.0.1"
    end

    teardown do
      CurrentUser.user = nil
      CurrentUser.ip_addr = nil
    end

    context "A post disapproval" do
      setup do
        @post_1 = FactoryBot.create(:post, :is_pending => true)
        @post_2 = FactoryBot.create(:post, :is_pending => true)
      end

      context "made by alice" do
        setup do
          @disapproval = PostDisapproval.create(:user => @alice, :post => @post_1)
        end

        context "when the current user is alice" do
          setup do
            CurrentUser.user = @alice
          end

          should "remove the associated post from alice's moderation queue" do
            assert(!Post.available_for_moderation(false).map(&:id).include?(@post_1.id))
            assert(Post.available_for_moderation(false).map(&:id).include?(@post_2.id))
          end
        end

        context "when the current user is brittony" do
          setup do
            @brittony = FactoryBot.create(:moderator_user)
            CurrentUser.user = @brittony
          end

          should "not remove the associated post from brittony's moderation queue" do
            assert(Post.available_for_moderation(false).map(&:id).include?(@post_1.id))
            assert(Post.available_for_moderation(false).map(&:id).include?(@post_2.id))
          end
        end
      end

      context "#search" do
        should "work" do
          disapproval1 = FactoryBot.create(:post_disapproval, user: @alice, post: @post_1, reason: "breaks_rules")
          disapproval2 = FactoryBot.create(:post_disapproval, user: @alice, post: @post_2, reason: "poor_quality", message: "bad anatomy")

          assert_equal([disapproval1.id], PostDisapproval.search(reason: "breaks_rules").pluck(:id))
          assert_equal([disapproval2.id], PostDisapproval.search(message: "bad anatomy").pluck(:id))
          assert_equal([disapproval2.id, disapproval1.id], PostDisapproval.search(creator_name: "alice").pluck(:id))
        end
      end
    end
  end
end
