# frozen_string_literal: true

class ApiDocumentationController < ApplicationController
  layout(false)

  def show
  end

  def spec
    send_file(Rails.root.join("openapi.yaml"))
  end
end
