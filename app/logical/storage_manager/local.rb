# frozen_string_literal: true

module StorageManager
  class Local < StorageManager::Base
    DEFAULT_PERMISSIONS = 0o644

    def store(io, dest_path)
      log(%{store(io, "#{dest_path}")}) do
        temp_path = "#{dest_path}-#{SecureRandom.uuid}.tmp"

        FileUtils.mkdir_p(File.dirname(temp_path))
        io.rewind
        bytes_copied = IO.copy_stream(io, temp_path)
        raise(Error, "store failed: #{bytes_copied}/#{io.size} bytes copied") if bytes_copied != io.size

        FileUtils.chmod(DEFAULT_PERMISSIONS, temp_path)
        File.rename(temp_path, dest_path)
      rescue StandardError => e
        FileUtils.rm_f(temp_path)
        raise(Error, e)
      ensure
        FileUtils.rm_f(temp_path) if temp_path
      end
    end

    def delete(path)
      log(%{delete("#{path}")}) do
        FileUtils.rm_f(path)
      end
    end

    def open(path, &)
      log(%{open("#{path}")}) do
        file = File.open(path, "r", binmode: true)
        if block_given?
          begin
            yield(file)
          ensure
            file.close
          end
        else
          file
        end
      end
    end

    def move_file(old_path, new_path)
      log(%{move_file("#{old_path}", "#{new_path}")}) do
        if File.exist?(old_path)
          FileUtils.mkdir_p(File.dirname(new_path))
          FileUtils.mv(old_path, new_path)
          FileUtils.chmod(DEFAULT_PERMISSIONS, new_path)
        end
      end
    end
  end
end
