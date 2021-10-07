namespace :custom do
  desc "Regenerate Packs"
  task regen: :environment do
    FileUtils.remove_dir(Rails.root.join("public", "packs"))
    Dir.chdir(Rails.root) do
        %x( "RAILS_ENV=production bin/rake assets:precompile" )
    end
  end
end
