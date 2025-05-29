#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

ModAction.without_logging do
  HelpPage.find_each do |help|
    help.update!(wiki_page_title: help.wiki_page_in_database)
  end

  ModAction.where(action: %i[help_create help_update help_delete]).find_each do |mod|
    mod.update!(values: { name: mod.name, wiki_page_title: mod.wiki_page, wiki_page_id: WikiPage.titled(mod.wiki_page)&.id })
  end
end
