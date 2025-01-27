# frozen_string_literal: true

class MascotsController < ApplicationController
  respond_to :html, :json

  def index
    @mascots = authorize(Mascot).search(search_params(Mascot)).paginate(params[:page], limit: params[:limit])
    respond_with(@mascots)
  end

  def new
    @mascot = authorize(Mascot.new(permitted_attributes(Mascot)))
  end

  def edit
    @mascot = authorize(Mascot.find(params[:id]))
  end

  def create
    @mascot = authorize(Mascot.new(permitted_attributes(Mascot)))
    @mascot.save
    respond_with(@mascot, location: mascots_path)
  end

  def update
    @mascot = authorize(Mascot.find(params[:id]))
    @mascot.update(permitted_attributes(@mascot))
    respond_with(@mascot, location: mascots_path)
  end

  def destroy
    @mascot = authorize(Mascot.find(params[:id]))
    @mascot.destroy
    respond_with(@mascot)
  end
end
