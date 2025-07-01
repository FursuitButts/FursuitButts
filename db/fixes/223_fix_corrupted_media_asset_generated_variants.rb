#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

MediaAssetWithVariants.descendants.each do |klass|
  Rails.logger.info(klass.name)
  klass.where("generated_variants = ?", [nil].to_json).find_each do |media_asset|
    Rails.logger.info("#{klass} #{media_asset.id}")
    types = media_asset.variants_data.pluck("type") - %w[original]
    if types.blank?
      Rails.logger.warn("No variants data found for #{media_asset.id}, skipping.")
      next
    end
    media_asset.update_columns(generated_variants: types)
  end
end
