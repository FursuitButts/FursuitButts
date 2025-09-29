# frozen_string_literal: true

class MascotMediaAssetPolicy < MediaAssetPolicy
  undef_method(:append?)
  undef_method(:finalize?)
  undef_method(:cancel?)
end
