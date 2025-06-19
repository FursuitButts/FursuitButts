# frozen_string_literal: true

module BulkUpdateRequestCommands
  class CreateImplication < Base
    set_command(:create_implication)
    set_arguments(:antecedent_name, :consequent_name, :comment)
    set_regex(/\A(?:create implication|imply) (\S+) -> (\S+)(?: # ?(.*))?\z/i, %i[tag tag pass])
    set_untokenize { |antecedent_name, consequent_name, comment| "imply #{antecedent_name} -> #{consequent_name}#{" # #{comment}" if comment}" }
    set_to_dtext { |antecedent_tag, consequent_tag, comment| "imply [[#{antecedent_tag.name}]] (#{antecedent_tag.post_count}) -> [[#{consequent_tag.name}]] (#{consequent_tag.post_count})#{" # #{comment}" if comment}" }

    validate(:no_duplicates)
    validate(:implication_is_valid)

    def no_duplicates
      tag_implication = TagImplication.duplicate_relevant.find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      return if tag_implication.blank?
      comments.add(:base, "duplicate of implication ##{tag_implication.id}")
    end

    def implication_is_valid
      tag_implication = TagImplication.new(status: "pending", antecedent_name: antecedent_name, consequent_name: consequent_name)
      return if tag_implication.valid?
      errors.add(:base, "Error: #{tag_implication.errors.full_messages.join('; ')}")
    end

    def estimate_update_count
      TagImplication.new(antecedent_name: antecedent_name, consequent_name: consequent_name).estimate_update_count
    end

    def tags
      [antecedent_name, consequent_name]
    end

    def approved?
      TagImplication.duplicate_relevant.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name)
    end

    def failed?
      TagImplication.errored.exists?(antecedent_name: antecedent_name, consequent_name: consequent_name)
    end

    def process(processor, approver)
      ensure_valid!
      tag_implication = TagImplication.duplicate_relevant.find_by(antecedent_name: antecedent_name, consequent_name: consequent_name)
      if tag_implication.present?
        return unless tag_implication.status == "pending"
        tag_implication.update_columns(creator_id: processor.creator_id, creator_ip_addr: processor.creator_ip_addr, forum_topic_id: processor.topic_id)
      else
        tag_implication = TagImplication.create do |ti|
          ti.forum_topic_id = processor.topic_id
          ti.status = "pending"
          ti.antecedent_name = antecedent_name
          ti.consequent_name = consequent_name
          ti.creator_id = processor.creator.id
          ti.creator_ip_addr = processor.creator_ip_addr
        end
        unless tag_implication.valid?
          raise(ProcessingError, "Error: #{tag_implication.errors.full_messages.join('; ')} (create implication #{antecedent_name} -> #{consequent_name})")
        end
      end

      tag_implication.approve!(approver: approver, update_topic: false)
    end
  end
end
