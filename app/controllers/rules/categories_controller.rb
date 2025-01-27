# frozen_string_literal: true

module Rules
  class CategoriesController < ApplicationController
    respond_to :html, except: %i[index]
    respond_to :json
    respond_to :js, only: %i[reorder]

    def index
      @categories = authorize(RuleCategory).order(:order).paginate(params[:page], limit: params[:limit])
      respond_with(@categories)
    end

    def new
      @category = authorize(RuleCategory.new)
    end

    def edit
      @category = authorize(RuleCategory.find(params[:id]))
    end

    def create
      @category = authorize(RuleCategory).new(permitted_attributes(RuleCategory))
      @category.save
      notice(@category.errors.any? ? @category.errors.full_messages.join(";") : "Category created")
      respond_with(@category, location: rules_path)
    end

    def update
      @category = authorize(RuleCategory.find(params[:id]))
      @category.update(permitted_attributes(@category))
      notice(@category.errors.any? ? @category.errors.full_messages.join(";") : "Category updated")
      respond_with(@category, location: rules_path)
    end

    def destroy
      @category = authorize(RuleCategory.find(params[:id]))
      @category.destroy
      notice("Category deleted")
      respond_with(@category, location: rules_path)
    end

    def order
      @categories = authorize(RuleCategory).order(:order)
    end

    def reorder
      authorize(RuleCategory)
      return render_expected_error(400, "No categories provided") unless params[:_json].is_a?(Array) && params[:_json].any?
      changes = 0
      RuleCategory.transaction do
        params[:_json].each do |data|
          category = RuleCategory.find(data[:id])
          category.update_attribute(:order, data[:order])
          changes += 1 if category.previous_changes.any?
        end

        categories = RuleCategory.all
        if categories.any? { |rule| !rule.valid? }
          errors = []
          categories.each do |rule|
            errors << { id: rule.id, name: rule.name, message: rule.errors.full_messages.join("; ") } if !rule.valid? && rule.errors.any?
          end
          render(json: { success: false, errors: errors }, status: 422)
          raise(ActiveRecord::Rollback)
        else
          RuleCategory.log_reorder(changes) if changes != 0
          respond_to do |format|
            format.json { head(204) }
            format.js do
              render(json: { html: render_to_string(partial: "rules/categories/sort", locals: { categories: RuleCategory.order(:order) }) })
            end
          end
        end
      end
    rescue ActiveRecord::RecordNotFound
      render_expected_error(400, "Category not found")
    end
  end
end
