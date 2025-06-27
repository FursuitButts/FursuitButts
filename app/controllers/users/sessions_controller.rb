# frozen_string_literal: true

module Users
  class SessionsController < ApplicationController
    respond_to(:html, :json)

    def index
      @user_sessions = authorize(UserSession).search_current(search_params(UserSession))
                                             .paginate(params[:page], limit: params[:limit])
      respond_with(@user_sessions)
    end
  end
end
