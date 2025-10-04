# frozen_string_literal: true

class MascotMediaAsset < MediaAsset
  has_one(:mascot)

  module StorageMethods
    def path_prefix
      FemboyFans.config.mascot_path_prefix
    end

    def is_protected?
      false
    end
  end

  module FileMethods
    def validate_file
      FileValidator.new(self, file.path).validate(max_file_sizes: Config.instance.max_mascot_file_sizes.transform_values { |v| v * 1.kilobyte }, max_width: Config.instance.max_mascot_width, max_height: Config.instance.max_mascot_height)
    end
  end

  include(StorageMethods)
  include(FileMethods)

  def self.available_includes
    %i[creator mascot]
  end
end
