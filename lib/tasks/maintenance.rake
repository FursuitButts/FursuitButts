# frozen_string_literal: true

namespace :maintenance do
  desc "Run daily maintenance jobs"
  task daily: :environment do
    Maintenance.daily
  end
  desc "Run hourly maintenance jobs"
  task hourly: :environment do
    Maintenance.hourly
  end
end
