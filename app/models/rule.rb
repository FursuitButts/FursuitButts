# frozen_string_literal: true

class Rule < ApplicationRecord
  belongs_to_creator
  belongs_to_updater
  belongs_to(:category, class_name: "RuleCategory")
  validates(:name, presence: true, uniqueness: { case_sensitive: false }, length: { min: 3, maximum: 100 })
  validates(:description, presence: true, length: { maximum: 50_000 })
  validates(:order, uniqueness: { scope: :category_id }, numericality: { only_integer: true, greater_than: 0 })
  has_many(:quick_rules, -> { order(:order) })

  before_validation(on: :create) do
    self.order = (Rule.where(category: category).maximum(:order) || 0) + 1 if order.blank?
    self.anchor = name.parameterize if anchor.blank?
  end

  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:log_delete)

  module LogMethods
    def log_create
      ModAction.log!(:rule_create, self, name: name, description: description, category_name: category.name)
    end

    def log_update
      return unless saved_change_to_name? || saved_change_to_description? || saved_change_to_category_id?
      ModAction.log!(:rule_update, self,
                     name:              name,
                     old_name:          name_before_last_save,
                     description:       description,
                     old_description:   description_before_last_save,
                     category_name:     category.name,
                     old_category_name: RuleCategory.find_by(id: category_id_before_last_save)&.name || "Unknown: #{category_id_before_last_save}")
    end

    def log_delete
      ModAction.log!(:rule_delete, self, name: name, description: description, category_name: category.name)
    end
  end

  include(LogMethods)

  def self.log_reorder(changes)
    ModAction.log!(:rules_reorder, nil, total: changes)
  end

  def self.available_includes
    %i[category creator updater]
  end
end
