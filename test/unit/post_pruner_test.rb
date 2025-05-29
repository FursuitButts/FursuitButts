# frozen_string_literal: true

require("test_helper")

class PostPrunerTest < ActiveSupport::TestCase
  setup do
    @user = create(:admin_user)
    CurrentUser.user = @user
    @old_post = create(:post, created_at: 8.days.ago, is_pending: true)
    @appealed_post = create(:post, is_deleted: true)
    @old_appeal = create(:post_appeal, created_at: 8.days.ago, post: @appealed_post)

    PostPruner.new.prune!
  end

  should("prune expired pending posts") do
    @old_post.reload
    assert(@old_post.is_deleted?)
  end

  should("prune old pending appeals") do
    @old_appeal.reload
    assert(@old_appeal.rejected?)
  end
end
