# frozen_string_literal: true

namespace(:db_export) do
  desc("Run db export")
  task(create: :environment) do
    system("/app/db/export/exec", exception: true)
  end
end
