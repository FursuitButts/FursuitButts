# frozen_string_literal: true

class DtextPreviewsController < ApplicationController
  skip_forgery_protection(only: :create)

  def create
    body = params[:body] || ""
    dtext = helpers.format_text(body, **options)
    render(json: { html: dtext, posts: deferred_posts })
  end

  private

  def options
    opts = {}
    opts[:inline] = params[:inline].truthy? if params[:inline].present?
    opts[:disable_mentions] = params[:disable_mentions].truthy? if params[:disable_mentions].present?
    opts[:allow_color] = params[:allow_color].truthy? if params[:allow_color].present?
    opts[:qtags] = params[:qtags].truthy? if params[:qtags].present?
    opts[:max_thumbs] = params[:max_thumbs].to_i if params[:max_thumbs].present?
    opts
  end
end
