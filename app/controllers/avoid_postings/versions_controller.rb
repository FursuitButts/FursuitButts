# frozen_string_literal: true

module AvoidPostings
  class VersionsController < ApplicationController
    respond_to :html, :json

    def index
      @avoid_posting_versions = authorize(AvoidPostingVersion).html_includes(request, :updater, :avoid_posting)
                                                              .search(search_params(AvoidPostingVersion))
                                                              .paginate(params[:page], limit: params[:limit])
      respond_with(@avoid_posting_versions)
    end
  end
end
