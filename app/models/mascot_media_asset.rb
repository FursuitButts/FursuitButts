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
      FileValidator.new(self, file.path).validate(max_file_sizes: FemboyFans.config.max_mascot_file_sizes, max_width: FemboyFans.config.max_mascot_width, max_height: FemboyFans.config.max_mascot_height)
    end
  end

  module SearchMethods
    def search(params, user)
      q = super
      q = q.joins(:mascot).where("mascots.id": params[:mascot_id]) if params[:mascot_id].present?
      q
    end
  end

  include(StorageMethods)
  include(FileMethods)
  extend(SearchMethods)

  def self.available_includes
    %i[creator mascot]
  end
end
