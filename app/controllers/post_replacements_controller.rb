class PostReplacementsController < ApplicationController
  respond_to :html, :json
  before_action :member_only, only: [:create, :new]
  before_action :janitor_only, only: [:approve, :reject, :promote, :toggle_penalize]
  before_action :moderator_only, only: [:destroy]

  content_security_policy only: [:new] do |p|
    p.img_src :self, :data, "*"
  end

  def new
    check_allow_create
    @post = Post.find(params[:post_id])
    @post_replacement = @post.replacements.new
    respond_with(@post_replacement)
  end

  def create
    check_allow_create
    @post = Post.find(params[:post_id])
    @post_replacement = @post.replacements.create(create_params.merge(creator_id: CurrentUser.id, creator_ip_addr: CurrentUser.ip_addr))
    if @post_replacement.errors.any?
      flash[:notice] = @post_replacement.errors.full_messages.join('; ')
    else
      flash[:notice] = "Post replacement submitted"
    end
    respond_with(@post_replacement, location: @post)
  end

  def approve
    @post_replacement = PostReplacement.find(params[:id])
    @post_replacement.approve!(penalize_current_uploader: params[:penalize_current_uploader])

    respond_with(@post_replacement, location: post_path(@post_replacement.post))
  end

  def toggle_penalize
    @post_replacement = PostReplacement.find(params[:id])
    @post_replacement.toggle_penalize!

    respond_with(@post_replacement)
  end

  def reject
    @post_replacement = PostReplacement.find(params[:id])
    @post_replacement.reject!

    respond_with(@post_replacement, location: post_path(@post_replacement.post))
  end

  def destroy
    @post_replacement = PostReplacement.find(params[:id])
    @post_replacement.destroy

    respond_with(@post_replacement, location: post_path(@post_replacement.post))
  end

  def promote
    @post_replacement = PostReplacement.find(params[:id])
    @upload = @post_replacement.promote!
    if @post_replacement.errors.any?
      respond_with(@post_replacement)
    elsif @upload.errors.any?
      respond_with(@upload)
    else
      respond_with(@upload.post)
    end
  end

  def index
    params[:search][:post_id] = params.delete(:post_id) if params.key?(:post_id)
    @post_replacements = PostReplacement.includes(:post).visible(CurrentUser.user).search(search_params).paginate(params[:page], limit: params[:limit])

    respond_with(@post_replacements)
  end

  private

  def check_allow_create
    return if CurrentUser.can_replace?

    raise User::PrivilegeError, "You are not part of the replacements beta"
  end

  def create_params
    params.require(:post_replacement).permit(:replacement_url, :replacement_file, :reason, :source)
  end
end
