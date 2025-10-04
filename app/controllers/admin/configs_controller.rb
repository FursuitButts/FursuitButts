# frozen_string_literal: true

module Admin
  class ConfigsController < ApplicationController
    respond_to(:html, :json)
    def show
      @config = authorize(Config.uncached)
      respond_with(@config)
    end

    def update
      @config = authorize(Config.uncached)
      columns = Config.settable_columns(CurrentUser.user)
      column_names = columns.map(&:name)
      input = params[:config].permit!
      values = input.select { |name,| column_names.include?(name) }
      remaining = input.reject { |name,| values.keys.include?(name) }
      values = values.to_h do |key, value|
        col = columns.find { |c| c.name == key }
        if value.is_a?(Hash)
          next [key, value.reject { |_k, v| v == "" }.transform_values(&:to_i)]
        end
        next [key, value] if col&.null == true && value == ""
        next [key, value.to_i] if col&.type == :integer
        next [key, value.to_s.truthy?] if col&.type == :boolean
        [key, value]
      end
      return render_expected_error(400, "Unhandled value(s): #{remaining.keys.join(', ')}") unless remaining.empty?
      @config.update_with!(CurrentUser.user, values)
      notice("Config updated")
      respond_with(@config) do |format|
        format.html { redirect_back(fallback_location: admin_config_path) }
      end
    end
  end
end
