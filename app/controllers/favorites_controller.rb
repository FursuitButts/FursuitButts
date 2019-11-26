class FavoritesController < ApplicationController
  before_action :member_only, except: [:index]
  respond_to :html, :json, :js
  skip_before_action :api_check

  def index
    if params[:tags]
      redirect_to(posts_path(:tags => params[:tags]))
    else
      user_id = params[:user_id] || CurrentUser.user.id
      @user = User.find(user_id)

      if @user.hide_favorites?
        raise User::PrivilegeError.new
      end

      @favorite_set = PostSets::Post.new("fav:#{@user.name} status:any", params[:page],nil, params)
      respond_with(@favorite_set.posts) do |format|
        format.xml do
          render :xml => @favorite_set.posts.to_xml(:root => "posts")
        end
      end
    end
  end

  def create
    @post = Post.find(params[:post_id])
    FavoriteManager.add!(user: CurrentUser.user, post: @post)
    flash.now[:notice] = "You have favorited this post"

    respond_with(@post)
  end

  def destroy
    @post = Post.find_by_id(params[:id])
    FavoriteManager.remove!(user: CurrentUser.user, post: @post, post_id: params[:id])

    flash.now[:notice] = "You have unfavorited this post"
    respond_with(@post)
  end
end
