# frozen_string_literal: true

module MediaAssets
  class MascotsController < BaseController
    undef_method(:append)
    undef_method(:cancel)

    protected

    def asset_class
      MascotMediaAsset
    end
  end
end
