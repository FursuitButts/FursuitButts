# frozen_string_literal: true

class PoolsController < ApplicationController
  before_action :ensure_lockdown_disabled, except: %i[index show gallery]
  respond_to :html, :json

  def index
    @pools = authorize(Pool).search(search_params(Pool)).paginate(params[:page], limit: params[:limit])
    respond_with(@pools) do |format|
      format.json do
        render(json: @pools.to_json)
        expires_in(params[:expiry].to_i.days) if params[:expiry]
      end
    end
  end

  def show
    @pool = authorize(Pool.find(params[:id]))
    respond_with(@pool) do |format|
      format.html do
        @posts = @pool.posts.paginate_posts(params[:page], limit: params[:limit], total_count: @pool.post_ids.count)
      end
    end
  end

  def new
    @pool = authorize(Pool.new(permitted_attributes(Pool)))
    respond_with(@pool)
  end

  def edit
    @pool = authorize(Pool.find(params[:id]))
    respond_with(@pool)
  end

  def gallery
    @pools = authorize(Pool).search(search_params(Pool)).paginate_posts(params[:page], limit: params[:limit])
  end

  def create
    @pool = authorize(Pool.new(permitted_attributes(Pool)))
    @pool.save
    notice(@pool.valid? ? "Pool created" : @pool.errors.full_messages.join("; "))
    respond_with(@pool)
  end

  def update
    @pool = authorize(Pool.find(params[:id]))
    @pool.update(permitted_attributes(@pool))
    notice(@pool.valid? ? "Pool updated" : @pool.errors.full_messages.join("; "))
    respond_with(@pool)
  end

  def destroy
    @pool = authorize(Pool.find(params[:id]))
    @pool.destroy
    notice("Pool deleted")
    respond_with(@pool)
  end

  def revert
    @pool = authorize(Pool.find(params[:id]))
    @version = @pool.versions.find(params[:version_id])
    @pool.revert_to!(@version)
    flash[:notice] = "Pool reverted"
    respond_with(@pool, &:js)
  end

  def ensure_lockdown_disabled
    access_denied if Security::Lockdown.pools_disabled? && !CurrentUser.is_staff?
  end
end
