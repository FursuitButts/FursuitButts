# frozen_string_literal: true

module Users
  class EventsController < ApplicationController
    respond_to(:html, :json)

    def index
      @user_events = authorize(UserEvent).html_includes(request, :user)
                                         .visible(CurrentUser.user)
                                         .search(search_params(UserEvent))
                                         .paginate(params[:page], limit: params[:limit])
      respond_with(@user_events)
    end
  end
end
