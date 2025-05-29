# frozen_string_literal: true

class StatsController < ApplicationController
  respond_to(:html, :json)

  def index
    @stats = StatsUpdater.get
    respond_with(@stats)
  end
end
