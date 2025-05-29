# frozen_string_literal: true

namespace(:recommender) do
  desc("Train recommender")
  task(train!: :environment) do
    Recommender.train!
  end
end
