# frozen_string_literal: true

class Dmail < ApplicationRecord
  validates :title, :body, presence: { on: :create }
  validates :title, length: { minimum: 1, maximum: 250 }
  validates :body, length: { minimum: 1, maximum: FemboyFans.config.dmail_max_size }
  validate :recipient_accepts_dmails, on: :create
  validate :user_not_limited, on: :create
  validate :user_can_send_to, on: :create
  has_secure_token :key

  belongs_to :owner, class_name: "User"
  belongs_to :to, class_name: "User"
  belongs_to :from, class_name: "User"
  belongs_to :respond_to, class_name: "User", optional: true
  has_many :tickets, as: :model

  after_initialize :initialize_attributes, if: :new_record?
  before_create :auto_report_spam
  before_create :auto_read_if_filtered
  after_create :update_recipient
  after_commit :send_email, on: :create, unless: :no_email_notification

  attr_accessor :bypass_limits, :no_email_notification, :original

  module AddressMethods
    def to_name=(name)
      self.to_id = User.name_to_id(name)
    end

    def initialize_attributes
      self.from_id ||= CurrentUser.id
      self.creator_ip_addr ||= CurrentUser.ip_addr
    end
  end

  module FactoryMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def create_split(params)
        copy = nil

        Dmail.transaction do
          # recipient's copy
          copy = Dmail.new(params)
          copy.owner_id = copy.to_id
          copy.save unless copy.to_id == copy.from_id
          raise(ActiveRecord::Rollback) if copy.errors.any?

          # sender's copy
          copy = Dmail.new(params)
          copy.bypass_limits = true
          copy.owner_id = copy.from_id
          copy.is_read = true
          copy.save
        end

        copy
      end

      def create_automated(params)
        CurrentUser.as_system do
          dmail = Dmail.new(from: User.system, **params)
          dmail.owner = dmail.to
          dmail.save
          dmail
        end
      end
    end

    def build_response(options = {})
      Dmail.new do |dmail|
        if title =~ /Re:/
          dmail.title = title
        else
          dmail.title = "Re: #{title}"
        end
        dmail.owner_id = from_id
        dmail.original = self
        dmail.body = quoted_body
        dmail.to_id = respond_to_id || from_id unless options[:forward]
        dmail.from_id = to_id
      end
    end
  end

  module SearchMethods
    def sent_by_id(user_id)
      where(from_id: user_id).and(where.not(owner_id: user_id))
    end

    def sent_by(user)
      where(from_id: user.id).and(where.not(owner_id: user.id))
    end

    def owned_by_id(user_id)
      where(owner_id: user_id)
    end

    def owned_by(user)
      where(owner: user)
    end

    def not_owned_by_id(user_id)
      where.not(owner_id: user_id)
    end

    def not_owned_by(user)
      where.not(owner: user)
    end

    def active
      where(is_deleted: false)
    end

    def deleted
      where(is_deleted: true)
    end

    def read
      where(is_read: true)
    end

    def unread
      where(is_read: false, is_deleted: false)
    end

    def visible
      return all if CurrentUser.is_owner?
      where(owner_id: CurrentUser.id)
    end

    def for_folder(folder)
      return all if folder.nil?
      case folder
      when "all"
        where(owner_id: CurrentUser.id)
      when "sent"
        where(from_id: CurrentUser.id, owner_id: CurrentUser.id)
      when "received"
        where(to_id: CurrentUser.id, owner_id: CurrentUser.id)
      end
    end

    def search(params)
      q = super

      q = q.attribute_matches(:title, params[:title_matches])
      q = q.attribute_matches(:body, params[:message_matches])

      q = q.where_user(:to_id, :to, params)
      q = q.where_user(:from_id, :from, params)
      q = q.where_user(:owner_id, :owner, params)

      q = q.attribute_matches(:is_read, params[:is_read])
      q = q.attribute_matches(:is_deleted, params[:is_deleted])

      q = q.read if params[:read].to_s.truthy?
      q = q.unread if params[:read].to_s.falsy?

      q.order(created_at: :desc)
    end
  end

  include AddressMethods
  include FactoryMethods
  extend SearchMethods

  def user_not_limited
    return true if bypass_limits == true
    return true if from_id == User.system.id
    return true if from.is_janitor?

    # different throttle for restricted users, no newbie restriction & much more restrictive total limit
    if from.is_rejected? || from.is_restricted?
      allowed = CurrentUser.can_dmail_restricted_with_reason
      errors.add(:base, "You #{User.throttle_reason(allowed, 'daily')}.") if allowed != true
    else
      allowed = CurrentUser.can_dmail_with_reason
      if allowed != true
        errors.add(:base, "Sender #{User.throttle_reason(allowed)}")
        return
      end
      minute_allowed = CurrentUser.can_dmail_minute_with_reason
      if minute_allowed != true
        errors.add(:base, "Please wait a bit before trying to send again")
        return
      end
      day_allowed = CurrentUser.can_dmail_day_with_reason
      if day_allowed != true
        errors.add(:base, "Sender #{User.throttle_reason(day_allowed, 'daily')}")
        nil
      end
    end
  end

  def user_can_send_to
    return true unless from.is_rejected? || from.is_restricted?
    unless to.is_admin?
      errors.add(:to_name, "is not a valid recipient. You may only message admins")
      return false
    end
    true
  end

  def recipient_accepts_dmails
    unless to
      errors.add(:to_name, "not found")
      return false
    end
    return true if from_id == User.system.id
    return true if from.is_janitor?
    if to.disable_user_dmails
      errors.add(:to_name, "has disabled DMails")
      return false
    end
    if from.disable_user_dmails && !to.is_janitor?
      errors.add(:to_name, "is not a valid recipient while blocking DMails from others. You may only message janitors and above")
      return false
    end
    if to.is_blocking_messages_from?(from)
      errors.add(:to_name, "does not wish to receive DMails from you")
      false
    end
  end

  def quoted_body
    "[quote]\n@#{from.pretty_name} said:\n\n#{body}\n[/quote]\n\n"
  end

  def send_email
    if to.receive_email_notifications? && to.email =~ /@/ && owner_id == to.id
      UserMailer.dmail_notice(self).deliver_now
    end
  end

  def mark_as_read!
    update_column(:is_read, true)
    owner.update(unread_dmail_count: owner.dmails.unread.count)
    owner.notifications.unread.where(category: "dmail").and(owner.notifications.where("data->>'dmail_id' = ?", id.to_s)).each(&:mark_as_read!)
  end

  def mark_as_unread!
    update_column(:is_read, false)
    owner.update(unread_dmail_count: owner.dmails.unread.count)
    owner.notifications.read.where(category: "dmail").and(owner.notifications.where("data->>'dmail_id' = ?", id.to_s)).each(&:mark_as_unread!)
  end

  def is_automated?
    from == User.system
  end

  def is_sender?
    owner == from
  end

  def is_recipient?
    owner == to
  end

  def filtered?
    CurrentUser.dmail_filter.try(:filtered?, self) || false
  end

  def auto_read_if_filtered
    if owner_id != from_id && to.dmail_filter.try(:filtered?, self)
      self.is_read = true
    end
  end

  def auto_report_spam
    if is_recipient? && !is_sender? && SpamDetector.new(self, user_ip: creator_ip_addr.to_s).spam?
      self.is_deleted = true
      self.is_spam = true
      tickets << Ticket.new(creator: User.system, creator_ip_addr: "127.0.0.1", reason: "Spam.")
    end
  end

  def mark_spam!
    return if is_spam?
    update!(is_spam: true)
    return if spam_ticket.present?
    SpamDetector.new(self, user_ip: creator_ip_addr.to_s).spam!
  end

  def mark_not_spam!
    return unless is_spam?
    update!(is_spam: false)
    return if spam_ticket.blank?
    SpamDetector.new(self, user_ip: creator_ip_addr.to_s).ham!
  end

  def spam_ticket
    tickets.where(creator: User.system, reason: "Spam.").first
  end

  def update_recipient
    if owner_id != from_id && !is_deleted? && !is_read?
      to.update(unread_dmail_count: to.dmails.unread.count)
      to.notifications.create!(category: "dmail", data: { user_id: from_id, dmail_id: id, dmail_title: title })
    end
  end

  def visible_to?(user, key = nil)
    return true if user.is_owner?
    return true if user.is_moderator? && (from_id == User.system.id || Ticket.exists?(model: self) || key == self.key)
    return true if user.is_admin? && (to.is_admin? || from.is_admin?)
    owner_id == user.id
  end

  def self.available_includes
    %i[from to owner]
  end

  def visible?(user = CurrentUser.user)
    visible_to?(user)
  end
end
