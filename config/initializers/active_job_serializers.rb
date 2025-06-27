# frozen_string_literal: true

Rails.application.config.to_prepare do
  Rails.application.config.active_job.custom_serializers << UserResolvableSerializer
end
