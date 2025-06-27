# frozen_string_literal: true

require("test_helper")

class UserRevertTest < ActiveSupport::TestCase
  context("Reverting a user's changes") do
    setup do
      @creator = create(:user)
      @user = create(:user)

      @parent = create(:post, uploader: @creator)
      @post = create(:post, tag_string: "aaa bbb ccc invalid_source", rating: "q", source: "xyz", uploader: @creator)

      @post.update_with(@user, tag_string: "bbb ccc xxx invalid_source", source: "", rating: "e")
    end

    subject { UserRevert.new(@user.id, @user) }

    should("have the correct data") do
      assert_equal("bbb ccc xxx", @post.tag_string)
      assert_equal("", @post.source)
      assert_equal("e", @post.rating)
    end

    context("when processed") do
      should("revert the user's changes") do
        subject.process
        @post.reload

        assert_equal("aaa bbb ccc invalid_source", @post.tag_string)
        assert_equal("xyz", @post.source)
        assert_equal("q", @post.rating)
      end

      context("when the user has an upload") do
        setup do
          create(:post, uploader: @user)
        end

        should("not raise") do
          assert_nothing_raised { subject.process }
        end
      end
    end
  end
end
