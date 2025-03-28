# frozen_string_literal: true

module Posts
  class EventsController < ApplicationController
    respond_to :html, :json

    def index
      @events = authorize(PostEvent).html_includes(request, :creator)
                                    .search(search_params(PostEvent))
                                    .paginate(params[:page], limit: params[:limit])
      respond_with(@events)
    end
  end
end
