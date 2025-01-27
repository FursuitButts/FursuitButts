# frozen_string_literal: true

class FixerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)
  class_option :elasticsearch, type: :boolean, default: false, aliases: %w[-e --elastic --opensearch --os]

  def create_fixer
    elastic = options["elasticsearch"]
    id = Dir["db/fixes/*.rb"].map { |f| File.basename(f, ".rb") }.max.to_i + 1
    if elastic
      copy_file("fixer_elastic.rb", "db/fixes/#{id}_1_#{file_name}.rb", mode: :preserve)
      copy_file("fixer.rb", "db/fixes/#{id}_2_#{file_name}.rb", mode: :preserve)
    else
      copy_file("fixer.rb", "db/fixes/#{id}_#{file_name}.rb", mode: :preserve)
    end
  end
end
