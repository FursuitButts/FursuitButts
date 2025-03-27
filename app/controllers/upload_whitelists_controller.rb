# frozen_string_literal: true

class UploadWhitelistsController < ApplicationController
  respond_to :html, :json, :js
  before_action :load_whitelist, only: %i[edit update destroy]

  def index
    @whitelists = authorize(UploadWhitelist).search(search_params(UploadWhitelist))
                                            .paginate(params[:page], limit: params[:limit])
    respond_with(@whitelists)
  end

  def new
    @whitelist = authorize(UploadWhitelist.new)
  end

  def edit
    authorize(@whitelist)
    respond_with(@whitelist)
  end

  def create
    @whitelist = authorize(UploadWhitelist.new(permitted_attributes(UploadWhitelist)))
    @whitelist.save
    respond_with(@whitelist, location: upload_whitelists_path)
  end

  def update
    authorize(@whitelist)
    @whitelist.update(permitted_attributes(@whitelist))
    notice(@whitelist.valid? ? "Entry updated" : @whitelist.errors.full_messages.join("; "))
    redirect_to(upload_whitelists_path)
  end

  def destroy
    authorize(@whitelist)
    @whitelist.destroy
    respond_with(@whitelist)
  end

  def is_allowed
    authorize(UploadWhitelist)
    begin
      url_parsed = Addressable::URI.heuristic_parse(params[:url])
      allowed, reason = UploadWhitelist.is_whitelisted?(url_parsed)
      @whitelist = {
        url:        params[:url],
        domain:     url_parsed.domain,
        is_allowed: allowed,
        reason:     reason,
      }
    rescue Addressable::URI::InvalidURIError
      @whitelist = {
        url:        params[:url],
        domain:     "invalid domain",
        is_allowed: false,
        reason:     "invalid domain",
      }
    end
    respond_with(@whitelist) do |format|
      format.json { render(json: @whitelist) }
    end
  end

  private

  def load_whitelist
    @whitelist = UploadWhitelist.find(params[:id])
  end
end
