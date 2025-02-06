# frozen_string_literal: true

class UploadService
  module Utils
    module_function

    class CorruptFileError < RuntimeError; end

    IMAGE_TYPES = %i[original large preview crop].freeze

    def delete_file(md5, file_ext, upload_id = nil)
      if Post.exists?(md5: md5)
        if upload_id.present? && Upload.exists?(id: upload_id)
          CurrentUser.as_system do
            Upload.find(upload_id).update(status: "completed")
          end
        end

        return
      end

      FemboyFans.config.storage_manager.delete_post_files(md5, file_ext)
    end

    def distribute_files(file, record, type, deleted: false, scale_factor: nil)
      # need to do this for hybrid storage manager
      [FemboyFans.config.storage_manager, FemboyFans.config.backup_storage_manager].each do |sm|
        sm.store(file, sm.file_path(record.md5, record.file_ext, type, protected: deleted, scale_factor: scale_factor))
      end
    end

    def generate_resizes(file, upload, frame: nil)
      PostThumbnailer.generate_resizes(file, upload.image_height, upload.image_width, upload.is_video? ? :video : :image, frame: frame)
    end

    def process_file(upload, file)
      upload.file = file
      upload.file_ext = upload.file_header_to_file_ext(file.path)
      upload.file_size = file.size
      upload.md5 = Digest::MD5.file(file.path).hexdigest

      width, height = calculate_dimensions(file.path)
      upload.image_width = width
      upload.image_height = height

      upload.validate!(:file)
      upload.tag_string = "#{upload.tag_string} #{Utils.automatic_tags(upload, file)}"

      # in case this upload never finishes processing, we need to delete the
      # distributed files in the future
      UploadDeleteFilesJob.set(wait: 24.hours).perform_later(upload.md5, upload.file_ext, upload.id)
    end

    def generate_samples(upload, file, deleted: false)
      preview_file, crop_file, sample_file, scaled, data = Utils.generate_resizes(file, upload)

      begin
        Utils.distribute_files(file, upload, :original, deleted: deleted)
        Utils.distribute_files(sample_file, upload, :large, deleted: deleted) if sample_file.present?
        Utils.distribute_files(preview_file, upload, :preview, deleted: deleted) if preview_file.present?
        Utils.distribute_files(crop_file, upload, :crop, deleted: deleted) if crop_file.present?
        scaled.each do |size, sfile|
          Utils.distribute_files(sfile, upload, :scaled, deleted: deleted, scale_factor: size)
        end
      ensure
        preview_file.try(:close!)
        crop_file.try(:close!)
        sample_file.try(:close!)
        scaled.each(&:close!)
      end

      # in case this upload never finishes processing, we need to delete the
      # distributed files in the future
      UploadDeleteFilesJob.set(wait: 24.hours).perform_later(upload.md5, upload.file_ext, upload.id)

      data
    end

    def automatic_tags(upload, file)
      return "" unless FemboyFans.config.enable_autotagging?

      tags = []
      tags += %w[animated_gif animated] if upload.is_animated_gif?(file.path)
      tags += %w[animated_png animated] if upload.is_animated_png?(file.path)
      tags += ["animated"] if upload.is_video?
      tags += ["ai_generated"] if upload.is_ai_generated?(file.path)
      tags.join(" ")
    end

    def get_file_for_upload(upload, file: nil)
      return file if file.present?
      raise("No file or source URL provided") if upload.direct_url.blank?

      download = Downloads::File.new(upload.direct_url)
      download.download!
    end

    def calculate_dimensions(file_path)
      ext = file_header_to_file_ext(file_path)
      klazz = Struct.new(:file_ext).new(file_ext: ext).extend(FileMethods) # messy, but dynamic
      if klazz.is_video?
        video = FFMPEG::Movie.new(file_path)
        [video.width, video.height]

      elsif klazz.is_image?
        image = Vips::Image.new_from_file(file_path)
        [image.width, image.height]

      else
        [0, 0]
      end
    end

    def file_header_to_file_ext(file_path)
      File.open(file_path) do |bin|
        mime_type = Marcel::MimeType.for(bin)
        case mime_type
        when "image/jpeg"
          "jpg"
        when "image/gif"
          "gif"
        when "image/png"
          "png"
        when "image/webp"
          "webp"
        when "video/webm"
          "webm"
        when "video/mp4"
          "mp4"
        else
          mime_type
        end
      end
    end

    def scaled_sample_dimensions(box, width, height)
      ratio = [box[0] / width.to_f, box[1] / height.to_f].min
      width = [[width * ratio, 2].max.ceil, box[0]].min & ~1
      height = [[height * ratio, 2].max.ceil, box[1]].min & ~1
      [width, height]
    end
  end
end
