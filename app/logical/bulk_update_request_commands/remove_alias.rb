# frozen_string_literal: true

module BulkUpdateRequestCommands
  class RemoveAlias < Base
    set_command(:remove_alias)
    set_arguments(:antecedent_name, :consequent_name, :comment)
    set_regex(/\A(?:remove alias|unalias) (\S+) -> (\S+)(?: # ?(.*))?\z/i, %i[tag tag pass])
    set_untokenize { |antecedent_name, consequent_name, comment| "unalias #{antecedent_name} -> #{consequent_name}#{" # #{comment}" if comment}" }
    set_to_dtext { |antecedent_tag, consequent_tag, comment| "unalias [[#{antecedent_tag.name}]] (#{antecedent_tag.post_count}) -> [[#{consequent_tag.name}]] (#{consequent_tag.post_count})#{" # #{comment}" if comment}" }

    validate(:alias_exists)

    def alias_exists
      tag_alias = TagAlias.active.select(:id).find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      if tag_alias.present?
        comments.add(:base, "alias ##{tag_alias.id}")
      else
        comments.add(:base, "missing")
      end
    end

    def tags
      [antecedent_name, consequent_name]
    end

    def approved?
      TagAlias.deleted.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name) || !TagAlias.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name)
    end

    def process(_processor, approver)
      ensure_valid!
      tag_alias = TagAlias.active.find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      raise(ProcessingError, "Alias #{antecedent_name} -> #{consequent_name} not found") if tag_alias.nil?
      tag_alias.reject!(approver, update_topic: false)
    end
  end
end
