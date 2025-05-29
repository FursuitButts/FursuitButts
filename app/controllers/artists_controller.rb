# frozen_string_literal: true

class ArtistsController < ApplicationController
  before_action(:load_artist, only: %i[edit update destroy revert])
  respond_to(:html, :json)

  def index
    if params[:name].present?
      @artist = Artist.find_by(name: Artist.normalize_name(params[:id]))
      if @artist.nil?
        return redirect_to(show_or_new_artists_path(name: params[:id])) if request.format.html?
        raise(ActiveRecord::RecordNotFound)
      end
      redirect_to(artist_path(@artist))
    end
    @artists = authorize(Artist).includes(:urls)
                                .search(search_params(Artist))
                                .paginate(params[:page], limit: params[:limit])
    respond_with(@artists) do |format|
      format.json do
        render(json: @artists.to_json(include: %i[urls]))
        expires_in(params[:expiry].to_i.days) if params[:expiry]
      end
    end
  end

  def show
    if params[:id] =~ /\A\d+\z/
      @artist = Artist.find(params[:id])
    else
      @artist = Artist.named(name: params[:id])
      unless @artist
        respond_to do |format|
          format.html do
            redirect_to(show_or_new_artists_path(name: params[:id]))
          end
          format.json do
            raise(ActiveRecord::RecordNotFound)
          end
        end
        return
      end
    end
    authorize(@artist)
    @post_set = PostSets::Post.new(@artist.name, 1, limit: 10)
    respond_with(@artist, methods: %i[domains], include: %i[urls])
  end

  def new
    @artist = authorize(Artist.new(permitted_attributes(Artist)))
    respond_with(@artist)
  end

  def edit
    authorize(@artist)
    respond_with(@artist)
  end

  def create
    @artist = authorize(Artist.new(permitted_attributes(Artist)))
    @artist.save
    respond_with(@artist)
  end

  def update
    authorize(@artist).update(permitted_attributes(@artist))
    notice(@artist.valid? ? "Artist updated" : @artist.errors.full_messages.join("; "))
    respond_with(@artist)
  end

  def destroy
    authorize(@artist).destroy
    respond_with(@artist) do |format|
      format.html do
        redirect_to(artists_path, notice: @artist.destroyed? ? "Artist deleted" : @artist.errors.full_messages.join("; "))
      end
    end
  end

  def revert
    authorize(@artist)
    @version = @artist.versions.find(params[:version_id])
    @artist.revert_to!(@version)
    respond_with(@artist)
  end

  def show_or_new
    @artist = authorize(Artist).named(params[:name])
    if @artist
      redirect_to(artist_path(@artist))
    else
      @artist = Artist.new(name: Artist.normalize_name(params[:name] || ""))
      @post_set = PostSets::Post.new(@artist.name, 1, limit: 10)
      respond_with(@artist)
    end
  end

  private

  def load_artist
    if params[:id] =~ /\A\d+\z/
      @artist = Artist.find(params[:id])
    else
      @artist = Artist.named(name: params[:id])
      raise(ActiveRecord::RecordNotFound) if @artist.blank?
    end
  end
end
