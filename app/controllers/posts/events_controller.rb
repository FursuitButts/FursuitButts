# frozen_string_literal: true

module Posts
  class EventsController < ApplicationController
    respond_to :html, :json

    def index
      authorize(PostEvent)
      @events = PostEventDecorator.decorate_collection(
        PostEvent.includes(:creator).search(search_params(PostEvent)).paginate(params[:page], limit: params[:limit]),
      )
      respond_with(@events) do |format|
        format.json do
          # FIXME: prevents using only parameter
          render(json: Draper.undecorate(@events))
        end
      end
    end
  end
end
