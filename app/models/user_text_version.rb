# frozen_string_literal: true

class UserTextVersion < ApplicationRecord
  belongs_to :updater, class_name: "User"
  belongs_to :user
  array_attribute :text_changes # "changes" is used by Rails

  CHANGE_TYPES = {
    about:     "About",
    artinfo:   "Artist Info",
    blacklist: "Blacklist",
  }.freeze

  def self.create_version(user)
    count = UserTextVersion.where(user: user).count
    if count == 0
      count += 1
      create({
        user:            user,
        updater:         user,
        updater_ip_addr: user.last_ip_addr || "0.0.0.0",
        about_text:      user.profile_about_before_last_save || user.profile_about,
        artinfo_text:    user.profile_artinfo_before_last_save || user.profile_artinfo,
        blacklist_text:  user.blacklisted_tags_before_last_save || user.blacklisted_tags,
        version:         1,
        text_changes:    [],
      })
    end
    create({
      user:            user,
      updater:         CurrentUser.user,
      updater_ip_addr: CurrentUser.ip_addr,
      about_text:      user.profile_about,
      artinfo_text:    user.profile_artinfo,
      blacklist_text:  user.blacklisted_tags,
      version:         count + 1,
      text_changes:    changes_for_create(user),
    })
  end

  def self.changes_for_create(user)
    latest = UserTextVersion.where(user: user).order(version: :desc).first
    return [] if latest.nil?
    changes = []
    changes << "about" if user.profile_about != latest.about_text
    changes << "artinfo" if user.profile_artinfo != latest.artinfo_text
    changes << "blacklist" if user.blacklisted_tags != latest.blacklist_text
    changes
  end

  def self.allowed_for?(user, type)
    return policy(user).blacklist? if type == :blacklist
    true
  end

  def allowed_for?(user, type)
    return policy(user).blacklist? if type == :blacklist
    UserTextVersion.allowed_for?(user, type)
  end

  def has_previous?
    !is_original? && previous.present?
  end

  def previous
    UserTextVersion.find_by(user: user, version: version - 1)
  end

  def empty_for?(user)
    return true if text_changes.empty?
    changes_for(user).empty?
  end

  def is_original?
    version == 1
  end

  def changes_for(user)
    text_changes.map(&:to_sym).select { |type| allowed_for?(user, type) }
  end

  def changes_for_pretty(user)
    changes_for(user).map { |c| CHANGE_TYPES[c] }.join(", ")
  end

  def changes_from(version, user)
    changes = []
    changes << :about if about_text != version.about_text && allowed_for?(user, :about)
    changes << :artinfo if artinfo_text != version.artinfo_text && allowed_for?(user, :artinfo)
    changes << :blacklist if blacklist_text != version.blacklist_text && allowed_for?(user, :blacklist)
    changes
  end

  def show_about?
    is_original? || text_changes.include?("about")
  end

  def show_artinfo?
    is_original? || text_changes.include?("artinfo")
  end

  def show_blacklist?
    is_original? || text_changes.include?("blacklist")
  end

  def is_single?(user)
    changes_for(user).length == 1
  end

  module SearchMethods
    def search(params)
      q = super

      q = q.where_user(:updater_id, :updater, params)
      q = q.where_user(:user_id, :user, params)

      if params[:about_matches]
        params.delete(:changes)
        q = q.attribute_matches(:about_text, params[:about_matches])
             .where("? = ANY(text_changes)", "About")
      end

      if params[:artinfo_matches]
        params.delete(:changes)
        q = q.attribute_matches(:artinfo_text, params[:artinfo_matches])
             .where("? = ANY(text_changes)", "Artist Info")
      end

      if params[:blacklist_matches]
        params.delete(:changes)
        q = q.attribute_matches(:blacklist_text, params[:blacklist_matches])
             .where("? = ANY(text_changes)", "Blacklist")
      end

      if params[:ip_addr].present?
        q = q.where("updater_ip_addr <<= ?", params[:ip_addr])
      end

      if params[:changes]
        q = q.where("? = ANY(text_changes)", params[:changes])
      end

      q.apply_basic_order(params)
    end
  end

  extend SearchMethods

  def self.available_includes
    %i[updater user]
  end

  def visible?(user = CurrentUser.user)
    user.is_moderator?
  end
end
