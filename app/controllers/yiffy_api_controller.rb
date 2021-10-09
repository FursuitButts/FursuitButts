require 'mimemagic'

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
    },
    DISABLED_CATEGORY = {
      code: 3,
      message: "This category has been disabled, please find an alternative."
    }
  end

  class PostSets
    class Bulge;          ID = 1,  NAME = "official_furry_yiff_bulge"       end
    class YiffGay;        ID = 2,  NAME = "official_furry_yiff_gay"         end
    class YiffStraight;   ID = 3,  NAME = "official_furry_yiff_straight"    end
    class YiffLesbian;    ID = 4,  NAME = "official_furry_yiff_lesbian"     end
    class YiffGynomorph;  ID = 5,  NAME = "official_furry_yiff_gynomorph"   end
    class YiffAndromorph; ID = 6,  NAME = "official_furry_yiff_andromorph"  end
    class YiffMaleSolo;   ID = 7,  NAME = "official_furry_yiff_male_solo"   end
    class YiffFemaleSolo; ID = 8,  NAME = "official_furry_yiff_female_solo" end
    class Butts;          ID = 9,  NAME = "official_furry_butts"            end
    class Boop;           ID = 10, NAME = "official_furry_boop"             end
    class Cuddle;         ID = 11, NAME = "official_furry_cuddle"           end
    class Flop;           ID = 12, NAME = "official_furry_flop"             end
    class Fursuit;        ID = 13, NAME = "official_furry_fursuit"          end
    class Hold;           ID = 14, NAME = "official_furry_hold"             end
    class Howl;           ID = 15, NAME = "official_furry_howl"             end
    class Hug;            ID = 16, NAME = "official_furry_hug"              end
    class Kiss;           ID = 17, NAME = "official_furry_kiss"             end
    class Lick;           ID = 18, NAME = "official_furry_lick"             end
    class Propose;        ID = 19, NAME = "official_furry_propose"          end
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
    when *%w[butts fursuitbutts] then @set = PostSet.find(PostSets::Butts::ID)
    when "boop" then @set = PostSet.find(PostSets::Boop::ID)
    when "cuddle" then @set = PostSet.find(PostSets::Cuddle::ID)
    when "flop" then @set = PostSet.find(PostSets::Flop::ID)
    when "fursuit" then @set = PostSet.find(PostSets::Fursuit::ID)
    when "hold" then @set = PostSet.find(PostSets::Hold::ID)
    when "howl" then @set = PostSet.find(PostSets::Howl::ID)
    when "hug" then @set = PostSet.find(PostSets::Hug::ID)
    when "kiss" then @set = PostSet.find(PostSets::Kiss::ID)
    when "lick" then @set = PostSet.find(PostSets::Lick::ID)
    when "propose" then @set = PostSet.find(PostSets::Propose::ID)
    else @set = nil
    end

    if @set == nil
      head 404
      render json: {
        success: false,
        error: APIErrors::INVALID_CATEGORY
      }.to_json
    elsif @set.post_count == 0
      head 501
      render json: {
        success: false,
        error: APIErrors::NO_POSTS
      }.to_json
    else
      render json: {
        success: true,
        images: @set.posts.map { |post| format_post(post) }
      }.to_json
    end
  end

  def yiff
    case params[:category].downcase
    when "bulge" then @set = PostSet.find(PostSets::Bulge::ID)
    when "gay" then  @set = PostSet.find(PostSets::YiffGay::ID)
    when "straight" then @set = PostSet.find(PostSets::YiffStraight::ID)
    when "lesbian" then @set = PostSet.find(PostSets::YiffLesbian::ID)
    when "gynomorph" then @set = PostSet.find(PostSets::YiffGynomorph::ID)
    when "andromorph" then @set = PostSet.find(PostSets::YiffAndromorph::ID)
    when *%w[solo-male solo_male] then @set = PostSet.find(PostSets::YiffMaleSolo::ID)
    when *%w[solo-female solo_female] then @set = PostSet.find(PostSets::YiffFemaleSolo::ID)
    else @set = nil
    end

    if @set == nil
      head 404
      render json: {
        success: false,
        error: APIErrors::INVALID_CATEGORY
      }.to_json
    elsif @set.post_count == 0
      head 501
      render json: {
        success: false,
        error: APIErrors::NO_POSTS
      }.to_json
    else
      render json: {
        success: true,
        images: @set.posts.map { |post| format_post(post) }
      }.to_json
    end
  end

  def format_post(post)
    {
      artists: post.tag_string_artist.split(" "),
      sources: post.source.split("\n"),
      width: post.image_width,
      height: post.image_height,
      url: post.file_url,
      type: MimeMagic.by_extension(post.file_ext).to_s,
      name: "#{post.md5}.#{post.file_ext}",
      id: post.id,
      shortURL: nil,
      ext: post.file_ext,
      size: post.file_size,
      reportURL: "https://#{Danbooru.config.hostname}/posts/#{post.id}",
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
      score: {
        up: post.up_score,
        down: post.down_score,
        total: post.score
      },
      createdAt: post.created_at,
      updatedAt: post.updated_at,
      md5: post.md5,
      rating: post.rating,
      uploader: post.uploader_id == nil ? nil : {
        id: post.uploader_id,
        name: post.uploader_name
      },
      approver: post.approver_id == nil ? nil : {
        id: post.approver_id,
        name: User.id_to_name(post.approver_id)
      }
    }
  end
end
