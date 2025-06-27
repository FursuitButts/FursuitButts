# frozen_string_literal: true

require("test_helper")

class ApplicationRecordTest < ActiveSupport::TestCase
  context("ApplicationRecord") do
    setup do
      @user = create(:user)
      @tags = create_list(:tag, 3, post_count: 1)
    end

    context("#search") do
      should("support the id param") do
        assert_equal([@tags.first], Tag.search({ id: @tags.first.id.to_s }, @user))
      end

      should("support ranges in the id param") do
        assert_equal(@tags.reverse, Tag.search({ id: ">=1" }, @user))
        assert_equal(@tags.reverse, Tag.search({ id: "#{@tags[0].id}..#{@tags[2].id}" }, @user))
        assert_equal(@tags.reverse, Tag.search({ id: @tags.map(&:id).join(",") }, @user))
      end

      should("support the created_at and updated_at params") do
        assert_equal(@tags.reverse, Tag.search({ created_at: ">=#{@tags.first.created_at}" }, @user))
        assert_equal(@tags.reverse, Tag.search({ updated_at: ">=#{@tags.first.updated_at}" }, @user))
      end
    end
  end
end
