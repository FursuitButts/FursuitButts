# frozen_string_literal: true

class TagAliasUndoJob < ApplicationJob
  queue_as(:tags)

  def perform(*args)
    ta = TagAlias.find(args[0])
    ta.process_undo!(User.find(args[1]), update_topic: args[2])
  end
end
