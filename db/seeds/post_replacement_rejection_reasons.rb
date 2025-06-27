# frozen_string_literal: true

module PostReplacementRejectionReasons
  def self.run!(user = User.system)
    [
      "Upscaled",
      "Different Image",
      "Lower Quality",
    ].each_with_index.map do |data, index|
      next if data == ""

      PostReplacementRejectionReason.find_or_create_by!(reason: data, order: index + 1, creator: user.resolvable)
    end
  end
end
