# frozen_string_literal: true

class ModActionsController < ApplicationController
  respond_to(:html, :json)

  def index
    @mod_actions = authorize(ModAction).html_includes(request, :creator)
                                       .search_current(search_params(ModAction))
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
