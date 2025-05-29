#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

WikiPage.find_in_batches(batch_size: 500) do |wiki_pages|
  WikiPage.transaction do
    wiki_pages.each do |wiki_page|
      DtextLink.new_from_dtext(wiki_page.body).each do |link|
        link.model = wiki_page
        link.save!
      end
    end
  end
end

ForumPost.find_in_batches(batch_size: 500) do |forum_posts|
  ForumPost.transaction do
    forum_posts.each do |forum_post|
      DtextLink.new_from_dtext(forum_post.body).each do |link|
        link.model = forum_post
        link.save!
      end
    end
  end
end
