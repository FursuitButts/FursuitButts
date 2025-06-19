# frozen_string_literal: true

module BulkUpdateRequestCommands
  class RemoveImplication < Base
    set_command(:remove_implication)
    set_arguments(:antecedent_name, :consequent_name, :comment)
    set_regex(/\A(?:remove implication|unimply) (\S+) -> (\S+)(?: # ?(.*))?\z/i, %i[tag tag pass])
    set_untokenize { |antecedent_name, consequent_name, comment| "unimply #{antecedent_name} -> #{consequent_name}#{" # #{comment}" if comment}" }
    set_to_dtext { |antecedent_tag, consequent_tag, comment| "unimply [[#{antecedent_tag.name}]] (#{antecedent_tag.post_count}) -> [[#{consequent_tag.name}]] (#{consequent_tag.post_count})#{" # #{comment}" if comment}" }

    validate(:implication_exists)

    def implication_exists
      tag_implication = TagImplication.duplicate_relevant.select(:id).find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      if tag_implication.present?
        comments.add(:base, "implication ##{tag_implication.id}")
      else
        comments.add(:base, "missing")
      end
    end

    def tags
      [antecedent_name, consequent_name]
    end

    def approved?
      TagImplication.deleted.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name) || !TagImplication.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name)
    end

    def process(_processor, approver)
      ensure_valid!
      tag_implication = TagImplication.active.find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      raise(ProcessingError, "Implication #{antecedent_name} -> #{consequent_name} not found") if tag_implication.nil?
      approver.scoped { tag_implication.reject!(update_topic: false) }
    end
  end
end
