# frozen_string_literal: true

require("test_helper")

class PostDisapprovalTest < ActiveSupport::TestCase
  context("A post disapproval") do
    setup do
      @alice = create(:moderator_user, name: "alice")
      @post1 = create(:post, is_pending: true)
      @post2 = create(:post, is_pending: true)
    end

    context("#search") do
      should("work") do
        disapproval1 = create(:post_disapproval, user: @alice, post: @post1, reason: "borderline_quality")
        disapproval2 = create(:post_disapproval, user: @alice, post: @post2, reason: "borderline_relevancy", message: "looks human")

        assert_equal([disapproval1.id], PostDisapproval.search({ reason: "borderline_quality" }, @alice).pluck(:id))
        assert_equal([disapproval2.id], PostDisapproval.search({ message: "looks human" }, @alice).pluck(:id))
        assert_equal([disapproval2.id, disapproval1.id], PostDisapproval.search({ creator_name: "alice" }, @alice).pluck(:id))
      end
    end
  end
end
