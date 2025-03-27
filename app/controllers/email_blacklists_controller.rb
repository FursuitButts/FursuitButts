# frozen_string_literal: true

class EmailBlacklistsController < ApplicationController
  respond_to :html, :json, :js

  def index
    @blacklists = authorize(EmailBlacklist).html_includes(request, :creator)
                                           .search(search_params(EmailBlacklist))
                                           .paginate(params[:page], limit: params[:limit])
    respond_with(@blacklists)
  end

  def new
    @blacklist = authorize(EmailBlacklist.new)
  end

  def create
    @blacklist = authorize(EmailBlacklist.new(permitted_attributes(EmailBlacklist)))
    @blacklist.save
    respond_with(@blacklist, location: email_blacklists_path)
  end

  def destroy
    @blacklist = authorize(EmailBlacklist.find(params[:id]))
    @blacklist.destroy
    respond_with(@blacklist)
  end
end
