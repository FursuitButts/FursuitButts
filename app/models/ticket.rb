# frozen_string_literal: true

class Ticket < ApplicationRecord
  belongs_to_creator counter_cache: "ticket_count"
  belongs_to :model, polymorphic: true
  belongs_to :claimant, class_name: "User", optional: true
  belongs_to :handler, class_name: "User", optional: true
  belongs_to :accused, class_name: "User", optional: true
  after_initialize :classify
  before_validation :initialize_fields, on: :create
  validates :reason, presence: true
  validates :reason, length: { minimum: 2, maximum: FemboyFans.config.ticket_max_size }
  validates :response, length: { minimum: 2, maximum: FemboyFans.config.ticket_max_size }, on: :update
  validates :report_type, presence: true
  validate :validate_model_type
  validate :validate_report_type
  enum :status, %i[pending partial approved rejected].index_with(&:to_s)
  after_create :autoban_accused_user
  after_update :log_update
  after_update :create_dmail
  validate :validate_model_exists, on: :create
  validate :validate_creator_is_not_limited, on: :create

  scope :for_creator, ->(uid) { where("creator_id = ?", uid) }
  scope :automated, -> { for_creator(User.system.id) }

  attr_accessor :record_type, :send_update_dmail

  MODEL_TYPES = %w[Artist Comment Dmail ForumPost Pool Post PostSet Tag User WikiPage].freeze

  # Permissions Table
  #
  # |    Type    |      Can Create     |    Details Visible   |
  # |:----------:|:-------------------:|:--------------------:|
  # |   Artist   |         Any         |  Janitor+ / Creator  |
  # |   Comment  |       Visible       | Moderator+ / Creator |
  # |    Dmail   | Visible & Recipient | Moderator+ / Creator |
  # | Forum Post |       Visible       | Moderator+ / Creator |
  # |    Pool    |         Any         |  Janitor+ / Creator  |
  # |    Post    |         Any         |  Janitor+ / Creator  |
  # |  Post Set  |       Visible       | Moderator+ / Creator |
  # |     Tag    |         Any         |  Janitor+ / Creator  |
  # |    User    |         Any         |  *Janitor+ / Creator |
  # |  Wiki Page |         Any         |  Janitor+ / Creator  |
  # |    Other   |         None        | Moderator+ / Creator |
  #
  # * Janitor+ can see details if the creator is Janitor+ or the ticket is a commendation, else Moderator+
  module TicketTypes
    module Artist
      def can_view?(user)
        user.is_janitor? || user.id == creator_id
      end

      def bot_target_name
        model&.name
      end
    end

    module Comment
      def can_view?(user)
        user.is_moderator? || (user.id == creator_id)
      end
    end

    module Dmail
      def can_create_for?(user)
        model&.visible?(user) && model.to_id == user.id
      end

      def can_view?(user)
        user.is_moderator? || (user.id == creator_id)
      end

      def bot_target_name
        model&.from&.name
      end
    end

    module ForumPost
      def can_view?(user)
        user.is_moderator? || (user.id == creator_id)
      end
    end

    module Pool
      def can_view?(user)
        user.is_janitor? || user.id == creator_id
      end

      def bot_target_name
        model&.name
      end
    end

    module Post
      def subject
        reason.split("\n")[0] || "Unknown Report Type"
      end

      def can_view?(user)
        user.is_janitor? || user.id == creator_id
      end

      def bot_target_name
        model&.uploader&.name
      end
    end

    module PostSet
      def can_view?(user)
        user.is_moderator? || user.id == creator_id
      end

      def bot_target_name
        model&.name
      end
    end

    module Tag
      def can_view?(user)
        user.is_janitor? || (user.id == creator_id)
      end

      def bot_target_name
        model&.name
      end
    end

    module User
      def can_view?(user)
        user.is_moderator? || user.id == creator_id || (user.is_janitor? && (report_type == "commendation" || creator.is_janitor?))
      end

      def bot_target_name
        model&.name
      end
    end

    module WikiPage
      def can_view?(user)
        user.is_janitor? || (user.id == creator_id)
      end

      def bot_target_name
        model&.title
      end
    end
  end

  module ValidationMethods
    def validate_model_type
      return if MODEL_TYPES.include?(model_type)
      errors.add(:model_type, "is not valid")
    end

    def validate_report_type
      return if report_type == "report"
      return if report_type == "commendation" && model_type == "User"
      errors.add(:report_type, "is not valid")
    end

    def validate_creator_is_not_limited
      return if creator == User.system
      allowed = creator.can_ticket_with_reason
      if allowed != true
        errors.add(:creator, User.throttle_reason(allowed))
        return false
      end
      true
    end

    def validate_model_exists
      errors.add(model.name.underscore.to_sym, "does not exist") if model.nil?
    end

    def initialize_fields
      self.status = "pending"
      case model
      when Comment, ForumPost
        self.accused_id = model.creator_id
      when Dmail
        self.accused_id = model.from_id
      when User
        self.accused_id = model_id
      end
    end
  end

  module SearchMethods
    def for_accused(user_id)
      where(accused_id: user_id)
    end

    def active
      where(status: %w[pending partial])
    end

    def visible(user)
      if user.is_moderator?
        all
      elsif user.is_janitor?
        for_creator(user.id).or(where(model_type: %w[Post]))
      else
        for_creator(user.id)
      end
    end

    def search(params)
      q = super.includes(:creator).includes(:claimant)

      if params[:creator_id].present? || params[:creator_name].present?
        # FIXME: This is more complicated than it needs to be
        if CurrentUser.is_moderator? || params[:creator_id].to_i == CurrentUser.user.id || params[:creator_name]&.downcase == CurrentUser.user.name.downcase
          q = q.where_user(:creator_id, :creator, params)
        else
          q = q.none
        end
      end
      q = q.where_user(:claimant_id, :claimant, params)
      q = q.where_user(:accused_id, :accused, params)

      if params[:model_type].present?
        q = q.where(model_type: params[:model_type])
      end

      if params[:model_id].present?
        q = q.where(model_id: params[:model_id])
      end

      if params[:reason].present?
        q = q.attribute_matches(:reason, params[:reason])
      end

      if params[:status].present?
        case params[:status]
        when "pending_claimed"
          q = q.where("status = ? and claimant_id is not null", "pending")
        when "pending_unclaimed"
          q = q.where("status = ? and claimant_id is null", "pending")
        else
          q = q.where("status = ?", params[:status])
        end
      end

      if params[:order].present?
        q.apply_basic_order(params)
      else
        q.order(Arel.sql("CASE status WHEN 'pending' THEN 0 WHEN 'partial' THEN 1 ELSE 2 END ASC, id DESC"))
      end
    end
  end

  module ClassifyMethods
    def classify
      extend(TicketTypes.const_get(model_type)) if TicketTypes.constants.map(&:to_s).include?(model_type)
    end
  end

  def report_type_pretty
    case report_type
    when "report"
      "reporting"
    when "commendation"
      "commending"
    else
      report_type
    end
  end

  def bot_target_name
    case model
    when Dmail
      model&.from&.name
    when WikiPage
      model&.title
    when Pool, User
      model&.name
    when Post
      model&.uploader&.name
    else
      model&.creator&.name
    end
  end

  def can_view?(user)
    user.is_moderator?
  end

  def can_see_reporter?(user)
    user.is_moderator? || (user.id == creator_id)
  end

  def can_create_for?(user)
    model.try(:visible?, user)
  end

  def type_title
    "#{model_type.titlecase} #{report_type.titlecase}"
  end

  def subject
    if reason.length > 40
      "#{reason[0, 38]}..."
    else
      reason
    end
  end

  def autoban_accused_user
    return if accused.blank?
    if SpamDetector.is_spammer?(accused)
      SpamDetector.ban_spammer!(accused)
    end
  end

  def open_duplicates
    Ticket.where(model: model, status: "pending")
  end

  def warnable?
    model.respond_to?(:user_warned!) && !model.was_warned? && pending?
  end

  def pretty_status
    if status == "partial"
      "Under Investigation"
    else
      status.titleize
    end
  end

  module ClaimMethods
    def claim!(user = CurrentUser)
      transaction do
        ModAction.log!(:ticket_claim, self)
        update_attribute(:claimant_id, user.id)
        push_pubsub("claim")
      end
    end

    def unclaim!(_user = CurrentUser)
      transaction do
        ModAction.log!(:ticket_unclaim, self)
        update_attribute(:claimant_id, nil)
        push_pubsub("unclaim")
      end
    end
  end

  module NotificationMethods
    def create_dmail
      return if creator == User.system
      should_send = saved_change_to_status? || (send_update_dmail.to_s.truthy? && saved_change_to_response?)
      return unless should_send

      msg = <<~MSG.chomp
        "Your ticket":#{Rails.application.routes.url_helpers.ticket_path(self)} has been updated by #{handler.pretty_name}.
        Ticket Status: #{status}

        Response: #{response}
      MSG
      title = "Your ticket has been updated"
      if saved_change_to_status?
        if %w[approved rejected].include?(status)
          title = "Your ticket has been #{pretty_status.downcase}"
        else
          title += " to #{pretty_status.downcase}"
        end
      end
      Dmail.create_split(
        from_id:       CurrentUser.id,
        to_id:         creator.id,
        title:         title,
        body:          msg,
        bypass_limits: true,
      )
    end

    def log_update
      return unless saved_change_to_response? || saved_change_to_status?

      ModAction.log!(:ticket_update, self)
    end
  end

  module PubSubMethods
    def pubsub_hash(action)
      {
        action: action,
        ticket: {
          id:          id,
          user_id:     creator_id,
          user_name:   creator_id ? User.id_to_name(creator_id) : nil,
          claimant:    claimant_id ? User.id_to_name(claimant_id) : nil,
          target:      bot_target_name,
          status:      status,
          model_id:    model_id,
          model_type:  model_type,
          report_type: report_type,
          reason:      reason,
        },
      }
    end

    def push_pubsub(action)
      # learned the hard way via receiving 25 pings during testing
      return if Rails.env.test?
      Cache.redis.publish("ticket_updates", pubsub_hash(action).to_json)
    end
  end

  include ClassifyMethods
  include ValidationMethods
  include ClaimMethods
  include NotificationMethods
  include PubSubMethods
  extend SearchMethods

  def self.available_includes
    %i[handler]
  end

  def visible?(user = CurrentUser.user)
    can_view?(user)
  end
end
