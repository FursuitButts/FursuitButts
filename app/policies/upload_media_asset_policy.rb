# frozen_string_literal: true

class UploadMediaAssetPolicy < MediaAssetWithVariantsPolicy
  def permitted_search_params
    super + %i[post_id]
  end
end
