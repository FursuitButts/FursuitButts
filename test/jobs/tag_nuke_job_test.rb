# frozen_string_literal: true

require("test_helper")

class TagNukeJobTest < ActiveJob::TestCase
  setup do
    CurrentUser.user = create(:user)
  end

  should("update posts") do
    p1 = create(:post, tag_string: "a aa b c d")
    p2 = create(:post, tag_string: "a dd y z")
    assert_difference("PostVersion.count", 2) do
      TagNukeJob.perform_now("a", create(:user).id)
      TagNukeJob.perform_now("b", create(:user).id)
    end
    p1.reload
    p2.reload
    assert_equal("aa c d", p1.tag_string)
    assert_equal("dd y z", p2.tag_string)
  end

  should("ignore aliases") do
    post = create(:post, tag_string: "extra new_tag")
    create(:tag_alias, antecedent_name: "old_tag", consequent_name: "new_tag", status: "active")
    TagNukeJob.perform_now("old_tag", CurrentUser.user.id)

    assert_equal("extra new_tag", post.reload.tag_string)
  end
end
