# frozen_string_literal: true

module SimpleVersioningMethods
  extend(ActiveSupport::Concern)

  class_methods do
    def simple_versioning(options = {})
      cattr_accessor(:versioning_body_column, :versioning_ip_column, :versioning_user_column, :versioning_subject_column, :versioning_is_hidden_column, :versioning_is_sticky_column, :versioning_updater_column, :versioning_updater_ip_column)
      self.versioning_body_column = options[:body_column] || "body"
      self.versioning_subject_column = options[:subject_column]
      self.versioning_ip_column = options[:ip_column] || "creator_ip_addr"
      self.versioning_user_column = options[:user_column] || "creator_id"
      self.versioning_is_hidden_column = options[:is_hidden_column] || "is_hidden"
      self.versioning_is_sticky_column = options[:is_sticky_column] || "is_sticky"
      self.versioning_updater_column = options[:updater_column] || "updater_id"
      self.versioning_updater_ip_column = options[:updater_ip_column] || "updater_ip_addr"

      class_eval do
        has_many(:versions, class_name: "EditHistory", as: :versionable)
        after_update(:save_version, if: :should_create_edited_history)
        after_save(if: :should_create_hidden_history) do |rec|
          type = rec.send("#{versioning_is_hidden_column}?") ? "hide" : "unhide"
          save_version(type)
        end
        after_save(if: :should_create_stickied_history) do |rec|
          type = rec.send("#{versioning_is_sticky_column}?") ? "stick" : "unstick"
          save_version(type)
        end

        define_method(:should_create_edited_history) do
          return true if versioning_subject_column && saved_change_to_attribute?(versioning_subject_column)
          saved_change_to_attribute?(versioning_body_column)
        end

        define_method(:should_create_hidden_history) do
          saved_change_to_attribute?(versioning_is_hidden_column)
        end

        define_method(:should_create_stickied_history) do
          saved_change_to_attribute?(versioning_is_sticky_column)
        end

        define_method(:save_original_version) do
          body = send("#{versioning_body_column}_before_last_save")
          body = send(versioning_body_column) if body.nil?

          subject = nil
          if versioning_subject_column
            subject = send("#{versioning_subject_column}_before_last_save")
            subject = send(versioning_subject_column) if subject.nil?
          end
          EditHistory.create! do |version|
            version.versionable = self
            version.version = 1
            version.updater_ip_addr = send(versioning_ip_column)
            version.body = body
            version.updater_id = send(versioning_user_column)
            version.subject = subject
            version.created_at = created_at
          end
        end

        define_method(:save_version) do |edit_type = "edit", extra_data = {}|
          EditHistory.transaction do
            our_next_version = next_version
            if our_next_version == 0
              save_original_version
              our_next_version += 1
            end

            body = send(versioning_body_column)
            subject = versioning_subject_column ? send(versioning_subject_column) : nil

            EditHistory.create! do |version|
              version.version = our_next_version + 1
              version.versionable = self
              version.updater_ip_addr = send(versioning_updater_ip_column)
              version.body = body
              version.subject = subject
              version.updater_id = send(versioning_updater_column)
              version.edit_type = edit_type
              version.extra_data = extra_data
            end
          end
        end

        define_method(:next_version) do
          versions.count
        end
      end
    end
  end
end
