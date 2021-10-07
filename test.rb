file = "temp.tmp"
ct = "test"

if(File.file?(file))
  content = File.read(file)
  puts "File Exists, Contents: %s" % [ content ]
else
  puts "File Does Not Exist, Writing.."
  File.write(file, ct)
end
