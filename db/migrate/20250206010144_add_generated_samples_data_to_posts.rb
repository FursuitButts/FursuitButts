# frozen_string_literal: true

class AddGeneratedSamplesDataToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column(:posts, :samples_data, :jsonb, null: false, default: [])
    change_column_default(:posts, :generated_samples, from: nil, to: [])
    change_column_null(:posts, :generated_samples, false)
  end
end
