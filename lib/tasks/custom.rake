namespace :custom do
  desc "Regenerate Packs"
  task regen: :environment do
    packs_dir = Rails.root.join("public", "packs")
    if(File.directory?(packs_dir))
        puts "Removing Packs Dir"
        FileUtils.remove_dir(packs_dir)
    else
        puts "Packs Dir Not Present"
    end
    
    puts "Running precompile (prod)"
    %x( "rake assets:precompile" )
  end
end
