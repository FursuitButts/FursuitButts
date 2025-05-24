# frozen_string_literal: true

class SystemsController < ApplicationController
  def show
    @info = authorize(SystemInfo.new).load_all
  end
end
