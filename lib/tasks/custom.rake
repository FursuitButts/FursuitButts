namespace :custom do
  desc "Regenerate Packs"
  task regen: :environment do
    packs_dir = Rails.root.join("public", "packs")
    if(File.directory?(packs_dir))
        echo "Removing Packs Dir"
        FileUtils.remove_dir(packs_dir)
    else
        echo "Packs Dir Not Present"
    end
    
    Dir.chdir(Rails.root) do
        echo "Runnung precompile (prod)"
        %x( "RAILS_ENV=production bin/rake assets:precompile" )
    end
  end
end
