class YiffyApiController < ApplicationController
  class APIErrors
    NOT_FOUND = {
      code: 0,
      message: "Not Found."
    },
    INVALID_CATEGORY = {
      code: 1,
      message: "Invalid Category."
    },
      NO_POSTS = {
      code: 2,
      message: "This category has no posts."
    }
  end

  class PostSets
    BULGE_NAME  = "official_bulge",
    BULGE_ID = 1,
    YIFF_GAY_NAME = "official_yiff_gay",
    YIFF_GAY_ID = 2,
    YIFF_STRAIGHT_NAME = "official_yiff_straight",
    YIFF_STRAIGHT_ID = 3,
    YIFF_LESBIAN_NAME = "official_yiff_lesbian",
    YIFF_LESBIAN_ID = 4,
    YIFF_GYNOMORPH_NAME = "official_yiff_gynomorph",
    YIFF_GYNOMORPH_ID = 5,
    YIFF_ANDROMORPH_NAME = "official_yiff_andromorph"
    YIFF_ANDROMORPH_ID = 6,
    YIFF_MALE_SOLO_NAME = "official_yiff_male_solo",
    YIFF_MALE_SOLO_ID = 7,
    YIFF_FEMALE_SOLO_NAME = "official_yiff_female_solo",
    YIFF_FEMALE_SOLO_ID = 8
  end

  def animals
    render json: {
      type: params[:category]
    }.to_json
  end

  def furry
    render json: {
      type: params[:category]
    }.to_json
  end

  def yiff
    render json: {
      type: params[:category]
    }.to_json
    case params[:category].downcase
    when "bulge" then @set = PostSet.find(PostSets::BULGE_ID)
    when "gay" then  @set = PostSet.find(PostSets::YIFF_GAY_ID)
    when "straight" then @set = PostSet.find(PostSets::YIFF_STRAIGHT_ID)
    when "lesbian" then @set = PostSet.find(PostSets::YIFF_LESBIAN_ID)
    when "gynomorph" then @set = PostSet.find(PostSets::YIFF_GYNOMORPH_ID)
    when "andromorph" then @set = PostSet.find(PostSets::YIFF_ANDROMORPH_ID)
    when *%w[solo-male solo_male] then @set = PostSet.find(PostSets::YIFF_MALE_SOLO_NAME)
    when *%w[solo-female solo_female] then @set = PostSet.find(PostSets::YIFF_FEMALE_SOLO_NAME)
    else @set = nil
    end

    if @set == nil
      render json: {
        success: false,
        error: APIErrors::INVALID_CATEGORY
      }.to_json
    elsif @set.post_count == 0
      render json: {
        success: false,
        error: APIErrors::NO_POSTS
      }.to_json
    else
      render json: {
        success: true,
        images: @set.posts.to_a
      }.to_json
    end
  end
end
