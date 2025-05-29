# frozen_string_literal: true

class TagsController < ApplicationController
  before_action(:load_tag, except: %i[index preview meta_search followed])
  respond_to(:html, :json)

  def index
    @tags = authorize(Tag).search(search_params(Tag))
                          .paginate(params[:page], limit: params[:limit])
    respond_with(@tags)
  end

  def preview
    authorize(Tag)
    @preview = TagsPreview.new(tags: params[:tags] || "")
    respond_to do |format|
      format.json do
        render(json: @preview.serializable_hash)
      end
    end
  end

  def meta_search
    authorize(Tag)
    @meta_search = MetaSearches::Tag.new(params)
    @meta_search.load_all
    respond_with(@meta_search)
  end

  def followed
    authorize(Tag)
    @user = User.find(params[:user_id] || CurrentUser.user.id)
    raise(User::PrivacyModeError) if @user.hide_followed_tags?

    @tags = @user.followed_tags.search(search_params(Tag)).paginate(params[:page], limit: params[:limit])
    respond_with(@tags.map(&:tag))
  end

  def followers
    @tag = authorize(Tag.find(params[:id]))
    query = User.joins(:followed_tags)
    unless CurrentUser.is_moderator?
      query = query.where("bit_prefs & :value != :value", { value: User.flag_value_for("enable_privacy_mode") }).or(query.where(tag_followers: { user_id: CurrentUser.id }))
    end
    query = query.where(tag_followers: { tag_id: @tag.id })
    query = query.order("users.name asc")
    @users = query.paginate(params[:page], limit: params[:limit])
    respond_with(@users)
  end

  def show
    authorize(@tag)
    respond_with(@tag)
  end

  def edit
    authorize(@tag)
    respond_with(@tag)
  end

  def update
    authorize(@tag)
    @tag.update(permitted_attributes(@tag))
    respond_with(@tag)
  end

  def correct
    authorize(Tag)
    @correction = TagCorrection.new(params[:id])
    @correction.fix!

    respond_to do |format|
      format.html { redirect_back(fallback_location: tags_path(search: { name_matches: @correction.tag.name, hide_empty: "no" }), notice: "Tag will be fixed in a few seconds") }
      format.json
    end
  end

  def follow
    @follower = authorize(@tag).follow!
    respond_with(@follower) do |format|
      format.html { redirect_back(fallback_location: tag_path(@tag), notice: "#{@tag.name} added to followed tags") }
    end
  rescue TagFollower::AliasedTagError
    respond_to do |format|
      format.html { redirect_back(fallback_location: tag_path(@tag), notice: "You cannot follow aliased tags") }
      format.json { render_expected_error(400, "You cannot follow aliased tags.") }
    end
  end

  def unfollow
    @follower = authorize(@tag).unfollow!
    respond_with(@follower) do |format|
      format.html { redirect_back(fallback_location: tag_path(@tag), notice: "#{@tag.name} removed from followed tags") }
    end
  end

  private

  def load_tag
    if params[:id] =~ /\A\d+\z/
      @tag = Tag.find(params[:id])
    else
      @tag = Tag.find_by!(name: params[:id])
    end
  end
end
