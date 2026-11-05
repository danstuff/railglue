require_relative "boot"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module Alpha
  class Application < Rails::Application
    config.load_defaults 8.1
    config.eager_load = false
  end
end
