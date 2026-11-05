# frozen_string_literal: true

# Serves the app under RAILGLUE_MOUNT_PATH without changing the app itself.
require File.expand_path('config/environment', Dir.pwd)

map ENV.fetch('RAILGLUE_MOUNT_PATH', '/') do
  run Rails.application
end
Rails.application.load_server
