# frozen_string_literal: true

module Notes
  class VersionsController < ApplicationController
    respond_to :html, :json

    def index
      @note_versions = authorize(NoteVersion).html_includes(request, :updater)
                                             .search(search_params(NoteVersion))
                                             .paginate(params[:page], limit: params[:limit])
      respond_with(@note_versions)
    end
  end
end
