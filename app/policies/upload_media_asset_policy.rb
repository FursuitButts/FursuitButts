# frozen_string_literal: true

class UploadMediaAssetPolicy < MediaAssetWithVariantsPolicy
  def permitted_search_params
    super + %i[upload_id post_id]
  end
end
