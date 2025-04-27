# frozen_string_literal: true

class MediaAssetWithVariantsPolicy < MediaAssetPolicy
  def api_attributes
    super - %i[generated_variants variants_data]
  end
end
