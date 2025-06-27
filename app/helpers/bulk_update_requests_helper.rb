# frozen_string_literal: true

module BulkUpdateRequestsHelper
  def script_with_line_breaks(bur, with_decorations:)
    cache_key = "#{'mod:' if CurrentUser.user.is_admin?}#{'color:' if with_decorations}#{bur.updated_at.utc.iso8601}"
    Cache.fetch(cache_key, expires_in: 1.hour) do
      processor = bur.processor
      commands = processor.commands
      script_tags = Tag.find_by_name_list(processor.tags)
      commands.map do |command|
        if with_decorations && command.approved?
          btag = "[color=green][s]"
          etag = "[/s][/color]"
        elsif with_decorations && command.failed?
          btag = "[color=red][s]"
          etag = "[/s][/color]"
        end
        token = command.tokenized
        token[-1] = nil if command.class.has_comment? && !bur.is_pending?
        command.class.groups.each_with_index do |value, index|
          next unless value == :tag
          token[index] = script_tags[token.at(index)] || Tag.new(name: token.at(index))
        end
        "#{btag}#{command.class.to_dtext(*token)}#{etag}"
      end.join("\n")
    rescue BulkUpdateRequestProcessor::Error
      "!!!!!!Invalid Script!!!!!!"
    end
  end

  def category_changes_for_bur(bur)
    bur.processor.category_changes
  end
end
