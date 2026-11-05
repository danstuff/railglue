# frozen_string_literal: true

require 'fileutils'

module Railglue
  # Writes the generated compose and nginx files for a Config.
  module Generator
    module_function

    def write(config)
      config.apps.each { |app| check_app_present(app) }
      FileUtils.mkdir_p(config.output_dir)
      File.write(config.compose_path, Compose.render(config))
      File.write(config.nginx_path, Nginx.render(config))
      config
    end

    def check_app_present(app)
      return if File.file?(File.join(app.path, 'Gemfile'))

      raise ConfigError, "#{app.name}: no Gemfile in #{app.path} " \
                         '(try: git submodule update --init)'
    end
  end
end
