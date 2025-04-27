# frozen_string_literal: true

module PostReplacementHelper
  def replacement_thumbnail(replacement)
    return tag.p("None") if replacement.uploading?
    if replacement.post.deleteblocked?
      image_tag(FemboyFans.config.deleted_preview_url)
    elsif replacement.post.visible?
      if replacement.original_file_visible_to?(CurrentUser)
        tag.a(image_tag(replacement.replacement_thumb_url), href: replacement.replacement_file_url)
      else
        image_tag(replacement.replacement_thumb_url)
      end
    end
  end
end
