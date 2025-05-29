# frozen_string_literal: true

module Rules
  class QuickController < ApplicationController
    respond_to(:html, :json)

    def index
      @quick = authorize(QuickRule).order(:order).paginate(params[:page], limit: params[:limit])
      respond_with(@quick)
    end

    def new
      @quick = authorize(QuickRule.new)
      @rules = Rule.joins(:category).order("rule_categories.order, rules.order")
      respond_with(@quick)
    end

    def edit
      @quick = authorize(QuickRule.find(params[:id]))
      @rules = Rule.joins(:category).order("rule_categories.order, rules.order")
      respond_with(@quick)
    end

    def create
      @quick = authorize(QuickRule.new(permitted_attributes(QuickRule)))
      @quick.save
      @rules = Rule.joins(:category).order("rule_categories.order, rules.order")
      notice(@quick.errors.any? ? @quick.errors.full_messages.join(", ") : "Quick rule created")
      respond_with(@quick, location: quick_rules_path)
    end

    def update
      @quick = authorize(QuickRule.find(params[:id]))
      @rules = Rule.joins(:category).order("rule_categories.order, rules.order")
      @quick.update(permitted_attributes(@quick))
      notice(@quick.errors.any? ? @quick.errors.full_messages.join(", ") : "Quick rule updated")
      respond_with(@quick, location: quick_rules_path)
    end

    def destroy
      @quick = authorize(QuickRule.find(params[:id]))
      @quick.destroy
      notice("Quick rule deleted")
      respond_with(@quick, location: quick_rules_path)
    end

    def order
      @quick = authorize(QuickRule).html_includes(request, :rule)
                                   .order(:order)
      respond_with(@quick)
    end

    def reorder
      authorize(QuickRule)
      return render_expected_error(400, "No quick rules provided") unless params[:_json].is_a?(Array) && params[:_json].any?
      changes = 0
      QuickRule.transaction do
        params[:_json].each do |data|
          quick = QuickRule.find(data[:id])
          quick.update_attribute(:order, data[:order])
          changes += 1 if quick.previous_changes.any?
        end

        list = QuickRule.all
        if list.any? { |quick| !quick.valid? }
          errors = []
          list.each do |quick|
            errors << { id: quick.id, name: quick.name, message: quick.errors.full_messages.join("; ") } if !quick.valid? && quick.errors.any?
          end
          render(json: { success: false, errors: errors }, status: 422)
          raise(ActiveRecord::Rollback)
        else
          QuickRule.log_reorder(changes) if changes != 0
          respond_to do |format|
            format.json { head(204) }
            format.js do
              render(json: { html: render_to_string(partial: "rules/quick/sort", locals: { list: QuickRule.order(:order) }) })
            end
          end
        end
      end
    rescue ActiveRecord::RecordNotFound
      render_expected_error(400, "Quick rule not found")
    end
  end
end
