class StaticController < ApplicationController
  def terms_of_service
    @page = WikiPage.find_by_title('e621:terms_of_service')
  end

  def accept_terms_of_service
    cookies.permanent[:accepted_tos] = "1"
    url = params[:url] if params[:url] && params[:url].start_with?("/")
    redirect_to(url || posts_path)
  end

  def not_found
    render "static/404", formats: [:html], status: 404
  end

  def error
  end

  def site_map
  end

  def takedown
  end

  def home
    render layout: "blank"
  end

  def theme
  end

  def disable_mobile_mode
    if CurrentUser.is_viewer? && !Danbooru.config.readonly_mode
      user = CurrentUser.user
      user.disable_responsive_mode = !user.disable_responsive_mode
      user.save
    else
      if cookies[:nmm]
        cookies.delete(:nmm)
      else
        cookies.permanent[:nmm] = '1'
      end
    end
    redirect_back fallback_location: posts_path
  end

  def discord
    unless CurrentUser.can_discord?
      raise User::PrivilegeError.new("You cannot join our server.")
      return
    end
    
    redirect_to(Danbooru.config.discord_site)
    end
  end

  def enforce_readonly
  end
end
