# frozen_string_literal: true

module BulkUpdateRequestCommands
  class CreateAlias < Base
    set_command(:create_alias)
    set_arguments(:antecedent_name, :consequent_name, :comment)
    set_regex(/\A(?:create alias|alias) (\S+) -> (\S+)(?: # ?(.*))?\z/i, %i[tag tag pass])
    set_untokenize { |antecedent_name, consequent_name, comment| "alias #{antecedent_name} -> #{consequent_name}#{" # #{comment}" if comment}" }
    set_to_dtext { |antecedent_tag, consequent_tag, comment| "alias [[#{antecedent_tag.name}]] (#{antecedent_tag.post_count}) -> [[#{consequent_tag.name}]] (#{consequent_tag.post_count})#{" # #{comment}" if comment}" }

    validate(:antecedent_exists)
    validate(:no_duplicates)
    validate(:alias_is_valid)

    def antecedent_exists
      comments.add(:base, "antecedent tag is missing") if antecedent_tag.blank?
    end

    def no_duplicates
      tag_alias = TagAlias.duplicate_relevant.find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      return if tag_alias.blank?
      comments.add(:base, "duplicate of alias ##{tag_alias.id}")
      comments.add(:base, "has blocking transitive relationships, cannot be applied through BUR") if tag_alias.has_transitives?
    end

    def alias_is_valid
      tag_alias = TagAlias.new(status: "pending", antecedent_name: antecedent_name, consequent_name: consequent_name)
      errors.add(:base, "Error: #{tag_alias.errors.full_messages.join('; ')}") unless tag_alias.valid?
      comments.add(:base, "has blocking transitive relationships, cannot be applied through BUR") if tag_alias.has_transitives?
    end

    def estimate_update_count
      TagAlias.new(antecedent_name: antecedent_name, consequent_name: consequent_name).estimate_update_count
    end

    def tags
      [antecedent_name, consequent_name]
    end

    def approved?
      TagAlias.duplicate_relevant.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name)
    end

    def failed?
      TagAlias.errored.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name)
    end

    def category_changes
      return [] if approved?
      tag, category = TagMover.new(antecedent_name, consequent_name, create_tags: false).tag_category_update
      return [] if category.blank?
      [[tag, category]]
    end

    def process(processor, approver)
      ensure_valid!
      tag_alias = TagAlias.duplicate_relevant.find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      if tag_alias.present?
        return unless tag_alias.status == "pending"
        tag_alias.update_columns(creator_id: processor.creator_id, creator_ip_addr: processor.creator_ip_addr, forum_topic_id: processor.topic_id)
      else
        tag_alias = TagAlias.create do |ta|
          ta.forum_topic_id = processor.topic_id
          ta.status = "pending"
          ta.antecedent_name = antecedent_name
          ta.consequent_name = consequent_name
          ta.creator_id = processor.creator.id
          ta.creator_ip_addr = processor.creator_ip_addr
        end
        unless tag_alias.valid?
          raise(ProcessingError, "Error: #{tag_alias.errors.full_messages.join('; ')} (alias #{antecedent_name} -> #{consequent_name})")
        end
      end

      raise(ProcessingError, "Error: Alias would modify other aliases or implications through transitive relationships. (alias #{tag_alias.antecedent_name} -> #{tag_alias.consequent_name})") if tag_alias.has_transitives
      tag_alias.approve!(approver: approver, update_topic: false)
    end
  end
end
