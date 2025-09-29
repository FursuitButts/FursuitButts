# frozen_string_literal: true

class Ticket < ApplicationRecord
  belongs_to_user(:creator, ip: true, clones: :updater, counter_cache: "ticket_count")
  belongs_to_user(:claimant, optional: true)
  belongs_to_user(:handler, ip: true, optional: true)
  belongs_to_user(:accused, optional: true)
  resolvable(:updater)
  belongs_to(:model, polymorphic: true)
  after_initialize(:classify)
  before_validation(:initialize_fields, on: :create)
  normalizes(:reason, with: ->(reason) { reason.gsub("\r\n", "\n") })
  validates(:reason, presence: true)
  validates(:reason, length: { minimum: 2, maximum: FemboyFans.config.ticket_max_size })
  validates(:response, length: { minimum: 2, maximum: FemboyFans.config.ticket_max_size }, on: :update)
  validates(:report_type, presence: true)
  validate(:validate_model_type)
  validate(:validate_report_type)
  enum(:status, %i[pending partial approved rejected].index_with(&:to_s))
  after_create(:autoban_accused_user)
  after_update(:log_update)
  after_update(:create_dmail)
  validate(:validate_model_exists, on: :create)
  validate(:validate_creator_is_not_limited, on: :create)

  scope(:automated, -> { for_creator(User.system) })
  scope(:spam, -> { automated.where(reason: "Spam.") })
  scope(:for_model, ->(type) { where(model_type: Array(type).map(&:to_s)) })
  scope(:active, -> { pending.or(partial) })
  scope(:claimed, -> { where.not(claimant_id: nil) })
  scope(:unclaimed, -> { where(claimant_id: nil) })

  attr_accessor(:record_type, :send_update_dmail)

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
      errors.add(:model, "does not exist") if model.nil?
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
    def creator_id_query(q, value, user)
      return none if !user.is_moderator? && value.to_i != user.id
      q.for_creator_id(value)
    end

    def creator_name_query(q, value, user)
      return none if !user.is_moderator? && value.downcase == user.name.downcase
      q.for_creator_name(value)
    end

    def status_query(q, value)
      case value
      when "pending_claimed"
        q.pending.claimed
      when "pending_unclaimed"
        q.pending.unclaimed
      else
        q.where(status: value)
      end
    end

    def default_order
      order(case_order(:status, ["pending", "partial", nil])).order(id: :desc)
    end

    def query_dsl
      super
        .field(:model_type)
        .field(:model_id)
        .field(:reason)
        .custom(:status, method(:status_query).to_proc)
        .custom(:creator_id, method(:creator_id_query).to_proc)
        .custom(:creator_name, method(:creator_name_query).to_proc)
        # TODO: We need access control/blocks for associations
        .association(:creator)
        .association(:claimant)
        .association(:accused)
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
      model&.from_name
    when WikiPage
      model&.title
    when Pool, User
      model&.name
    when Post
      model&.uploader_name
    else
      model&.creator_name
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
    def claim!(user)
      transaction do
        ModAction.log!(user, :ticket_claim, self)
        update(claimant: user, updater: user)
        push_pubsub("claim")
      end
    end

    def unclaim!(user)
      transaction do
        ModAction.log!(user, :ticket_unclaim, self)
        update(claimant: nil, updater: user)
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
      Dmail.create_split!(
        from:          handler,
        to:            creator,
        title:         title,
        body:          msg,
        bypass_limits: true,
      )
    end

    def log_update
      return unless saved_change_to_response? || saved_change_to_status?

      ModAction.log!(updater, :ticket_update, self)
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

  include(ClassifyMethods)
  include(ValidationMethods)
  include(ClaimMethods)
  include(NotificationMethods)
  include(PubSubMethods)
  extend(SearchMethods)

  def self.available_includes
    %i[handler]
  end

  def visible?(user)
    can_view?(user)
  end
end
