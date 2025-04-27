# frozen_string_literal: true

class PostReplacementMediaAssetPolicy < MediaAssetWithVariantsPolicy
  def permitted_search_params
    super + %i[post_replacement_id]
  end
end
