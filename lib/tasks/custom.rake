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
    
    puts "Runnung precompile (prod)"
    %x( "#{Rails.root}/bin/rake assets:precompile RAILS_ENV=production" )
  end
end
