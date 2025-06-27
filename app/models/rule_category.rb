# frozen_string_literal: true

class RuleCategory < ApplicationRecord
  belongs_to_user(:creator, ip: true, clones: :updater)
  belongs_to_user(:updater, ip: true)
  resolvable(:destroyer)

  validates(:name, presence: true, length: { min: 3, maximum: 100 }, uniqueness: { case_sensitive: false })
  validates(:anchor, length: { maximum: 100 })
  validates(:order, uniqueness: true, numericality: { only_integer: true, greater_than: 0 })
  has_many(:rules, -> { order(:order) }, dependent: :destroy, foreign_key: :category_id)
  after_create(:log_create)
  after_update(:log_update)
  before_destroy(:set_rules_destroyer, prepend: true)

  def set_rules_destroyer
    return if rules.blank? || destroyer.blank?
    rules.each { |rule| rule.destroyer = destroyer }
  end

  before_validation(on: :create) do
    self.order = (RuleCategory.maximum(:order) || 0) + 1 if order.blank?
    self.anchor = name.parameterize if name && anchor.blank?
  end

  def format_rules(category)
    rules = category.rules.map do |rule|
      "#{category.order}.#{rule.order} [[##{rule.anchor}|#{rule.title}]]"
    end
    rules.join("\n")
  end

  after_destroy(:log_delete)

  module LogMethods
    def log_create
      ModAction.log!(creator, :rule_category_create, self, name: name)
    end

    def log_update
      return unless saved_change_to_name?
      ModAction.log!(updater, :rule_category_update, self, name: name, old_name: name_before_last_save)
    end

    def log_delete
      ModAction.log!(destroyer, :rule_category_delete, self, name: name)
    end
  end

  include(LogMethods)

  def self.log_reorder(changes, user)
    ModAction.log!(user, :rule_categories_reorder, nil, total: changes)
  end

  def self.available_includes
    %i[creator updater]
  end
end
