# frozen_string_literal: true

module Artists
  class UrlsController < ApplicationController
    respond_to(:json, :html)

    def index
      @artist_urls = authorize(ArtistUrl).includes(:artist)
                                         .search_current(search_params(ArtistUrl))
                                         .paginate(params[:page], limit: params[:limit])
      respond_with(@artist_urls) do |format|
        # FIXME: this makes the only parameter not work
        format.json { render(json: @artist_urls.to_json(include: :artist)) }
      end
    end
  end
end
