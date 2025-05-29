# frozen_string_literal: true

class IpBansController < ApplicationController
  respond_to(:html, :json)

  def index
    @ip_bans = authorize(IpBan).html_includes(request, :creator)
                               .search(search_params(IpBan))
                               .paginate(params[:page], limit: params[:limit])
    respond_with(@ip_bans)
  end

  def new
    @ip_ban = authorize(IpBan.new(permitted_attributes(IpBan)))
  end

  def create
    @ip_ban = authorize(IpBan.new(permitted_attributes(IpBan)))
    @ip_ban.save
    respond_with(@ip_ban, location: ip_bans_path)
  end

  def destroy
    @ip_ban = authorize(IpBan.find(params[:id]))
    @ip_ban.destroy
    respond_with(@ip_ban)
  end
end
