# frozen_string_literal: true

module MentionableMethods
  extend(ActiveSupport::Concern)

  class_methods do
    def mentionable(options = {})
      cattr_accessor(:mentionable_body_column, :mentionable_notified_mentions_column, :mentionable_creator_column, :mentionable_updater_column)
      self.mentionable_body_column = options[:body_column] || "body"
      self.mentionable_notified_mentions_column = options[:notified_mentions_column] || "notified_mentions"
      self.mentionable_creator_column = options[:user_column] || "creator_id"
      self.mentionable_updater_column = options[:updater_column] || "updater_id"

      class_eval do
        after_save(:update_mentions, if: :should_update_mentions?)

        define_method(:should_update_mentions?) do
          saved_change_to_attribute?(mentionable_body_column) && send(mentionable_updater_column) == send(mentionable_creator_column) && send(mentionable_creator_column) != User.system.id
        end

        define_method(:update_mentions) do
          return unless should_update_mentions?

          DText.parse(send(mentionable_body_column)) => { mentions: }
          return if mentions.empty?
          sent = mentionable_notified_mentions_column.present? && respond_to?(mentionable_notified_mentions_column) ? send(mentionable_notified_mentions_column) : []
          userids = mentions.uniq.map { |name| User.name_to_id(name) }.compact.uniq
          unsent = userids - sent
          creator = send(mentionable_creator_column)
          return if unsent.empty?
          unsent.each do |user_id|
            # Save the user to the mentioned list regardless so they don't get a random notification for a future edit if they unblock the creator
            send(mentionable_notified_mentions_column) << user_id if mentionable_notified_mentions_column.present? && respond_to?(mentionable_notified_mentions_column)
            user = User.find(user_id)
            next if user.is_suppressing_mentions_from?(creator) || user.id == creator || user == User.system
            extra = {}
            type = self.class.name
            case type
            when "Comment"
              extra[:post_id] = post_id
            when "ForumPost"
              extra[:topic_id] = topic_id
              extra[:topic_title] = topic.title
            end
            user.notifications.create!(category: "mention", data: { mention_id: id, mention_type: type, user_id: creator, **extra })
          end
          save
        end

        define_method(:mentions) do
          notified_mentions.map { |id| { id: id, name: User.id_to_name(id) } }
        end
      end
    end
  end
end
