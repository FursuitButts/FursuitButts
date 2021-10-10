require 'mimemagic'

class YiffyApiController < ApplicationController
  class APIErrors
    NOT_FOUND = {
      code: 0,
      message: "Not Found."
    }
    INVALID_CATEGORY = {
      code: 1,
      message: "Invalid Category."
    }
    NO_POSTS = {
      code: 2,
      message: "This category has no posts."
    }
    DISABLED_CATEGORY = {
      code: 3,
      message: "This category has been disabled, please find an alternative."
    }
  end

  class PostSets
    BULGE             = 1
    YIFF_GAY          = 2
    YIFF_STRAIGHT     = 3
    YIFF_LESBIAN      = 4
    YIFF_GYNOMORPH    = 5
    YIFF_ANDROMORPH   = 6
    YIFF_MALE_SOLO    = 7
    YIFF_FEMALE_SOLO  = 8
    BUTTS             = 9
    BOOP              = 10
    CUDDLE            = 11
    FLOP              = 12
    FURSUIT           = 13
    HOLD              = 14
    HOWL              = 15
    HUG               = 16
    KISS              = 17
    LICK              = 18
    PROPOSE           = 19
    end

  def animals
    head 404
    render json: {
      success: false,
      error: APIErrors::DISABLED_CATEGORY
    }.to_json
  end

  def furry
    case params[:category].downcase
    when *%w[butts fursuitbutts] then @set = PostSet.find(PostSets::BUTTS)
    when "boop" then @set = PostSet.find(PostSets::BOOP)
    when "cuddle" then @set = PostSet.find(PostSets::CUDDLE)
    when "flop" then @set = PostSet.find(PostSets::FLOP)
    when "fursuit" then @set = PostSet.find(PostSets::FURSUIT)
    when "hold" then @set = PostSet.find(PostSets::HOLD)
    when "howl" then @set = PostSet.find(PostSets::HOWL)
    when "hug" then @set = PostSet.find(PostSets::HUG)
    when "kiss" then @set = PostSet.find(PostSets::KISS)
    when "lick" then @set = PostSet.find(PostSets::LICK)
    when "propose" then @set = PostSet.find(PostSets::PROPOSE)
    else @set = nil
    end

    if @set == nil
      render json: {
        "$schema": "https://img.yiff.rest/schema/v3_error.json",
        success: false,
        error: APIErrors::INVALID_CATEGORY
      }.to_json, status: :not_found
    elsif @set.post_count == 0
      render json: {
        "$schema": "https://img.yiff.rest/schema/v3_error.json",
        success: false,
        error: APIErrors::NO_POSTS
      }.to_json, status: :not_implemented
    else
      render json: {
        "$schema": "https://img.yiff.rest/schema/v3.json",
        success: true,
        images: @set.posts.sample(get_amount(params[:amount])).map { |post| format_post(post) }
      }.to_json
    end
  end

  def yiff
    case params[:category].downcase
    when "bulge" then @set = PostSet.find(PostSets::BULGE)
    when "gay" then  @set = PostSet.find(PostSets::YIFF_GAY)
    when "straight" then @set = PostSet.find(PostSets::YIFF_STRAIGHT)
    when "lesbian" then @set = PostSet.find(PostSets::YIFF_LESBIAN)
    when "gynomorph" then @set = PostSet.find(PostSets::YIFF_GYNOMORPH)
    when "andromorph" then @set = PostSet.find(PostSets::YIFF_ANDROMORPH)
    when *%w[solo-male solo_male] then @set = PostSet.find(PostSets::YIFF_MALE_SOLO)
    when *%w[solo-female solo_female] then @set = PostSet.find(PostSets::YIFF_FEMALE_SOLO)
    else @set = nil
    end

    if @set == nil
      render json: {
        "$schema": "https://img.yiff.rest/schema/v3_error.json",
        success: false,
        error: APIErrors::INVALID_CATEGORY
      }.to_json, status: :not_found
    elsif @set.post_count == 0
      render json: {
        "$schema": "https://img.yiff.rest/schema/v3_error.json",
        success: false,
        error: APIErrors::NO_POSTS
      }.to_json, status: :not_implemented
    else
      render json: {
        "$schema": "https://img.yiff.rest/schema/v3.json",
        success: true,
        images: @set.posts.sample(get_amount(params[:amount])).map { |post| format_post(post) }
      }.to_json
    end
  end

  def format_post(post)
    {
      approver: post.approver_id == nil ? nil : {
        id: post.approver_id,
        name: User.id_to_name(post.approver_id)
      },
      artists: post.tag_string_artist.split(" "),
      createdAt: post.created_at,
      directURL: "https://#{Danbooru.config.hostname}/posts/#{post.id}",
      ext: post.file_ext, # legacy
      height: post.image_height,
      id: post.id,
      md5: post.md5,
      name: "#{post.md5}.#{post.file_ext}", # legacy
      rating: post.rating,
      reportURL: "https://#{Danbooru.config.hostname}/posts/#{post.id}", # legacy
      score: {
        up: post.up_score,
        down: post.down_score,
        total: post.score
      },
      # removed due to urls now being shorter than the shortened urls
      shortURL: "https://#{Danbooru.config.hostname}/posts/#{post.id}", # legacy
      size: post.file_size,
      sources: post.source.split("\n"),
      tags: {
        general: post.tag_string_general.split(" "),
        species: post.tag_string_species.split(" "),
        character: post.tag_string_character.split(" "),
        copyright: post.tag_string_copyright.split(" "),
        artist: post.tag_string_artist.split(" "),
        invalid: post.tag_string_invalid.split(" "),
        lore: post.tag_string_lore.split(" "),
        meta: post.tag_string_meta.split(" ")
      },
      type: MimeMagic.by_extension(post.file_ext).to_s,
      updatedAt: post.updated_at,
      uploader: post.uploader_id == nil ? nil : {
        id: post.uploader_id,
        name: post.uploader_name
      },
      url: post.file_url,
      width: post.image_width
    }
  end

  def get_amount(p)
    # explicit conversion of nil to int gives 0
    p = p.to_i
    p < 1 || p > 5 ? 1 : p
  end
end
