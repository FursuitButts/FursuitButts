# frozen_string_literal: true

class MascotMediaAssetPolicy < MediaAssetPolicy
  undef_method :append?
  undef_method :finalize?
  undef_method :cancel?

  def permitted_search_params
    super + %i[mascot_id]
  end
end
