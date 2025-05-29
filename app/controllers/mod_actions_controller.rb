# frozen_string_literal: true

class ModActionsController < ApplicationController
  respond_to(:html, :json)

  def index
    # TODO: We need a way to construct urls without needing to load the model, as this results in needing to load many different
    # models on every page load. Using includes to load each in bulk is better, but it's still a single query per type,
    # resulting in up to LIMIT+1 queries per page on mod actions alone
    @mod_actions = authorize(ModAction).html_includes(request, :creator, :subject)
                                       .search(search_params(ModAction))
                                       .paginate(params[:page], limit: params[:limit])
    respond_with(@mod_actions)
  end

  def show
    @mod_action = authorize(ModAction.find(params[:id]))
    respond_with(@mod_action) do |fmt|
      fmt.html { redirect_to(mod_actions_path(search: { id: @mod_action.id })) }
    end
  end
end
