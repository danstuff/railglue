# frozen_string_literal: true

module Railglue
  class ConfigError < StandardError; end

  ROOT = File.expand_path('../..', __dir__)
  DEFAULT_CONFIG = File.join(ROOT, 'railglue.yml')
  DEFAULT_OUTPUT_ROOT = File.join(ROOT, '.railglue')
  MAX_APPS = 32
  APP_PORT = 3000
  DEFAULT_IMAGES = {
    'nginx' => 'nginx:1.28-alpine',
    'postgres' => 'postgres:18',
    'mysql' => 'mysql:8.4',
    'redis' => 'redis:8-alpine'
  }.freeze

  # One Rails app: where its code lives and where nginx mounts it.
  App = Struct.new(
    :name, :path, :mount, :database, :redis, :index, keyword_init: true
  ) do
    def root?
      mount == '/'
    end

    def database_name(env)
      "#{name.tr('-', '_')}_#{env}"
    end
  end

  # The whole environment, as described by railglue.yml.
  Config = Struct.new(
    :project, :port, :images, :apps, :output_root, keyword_init: true
  ) do
    def output_dir
      File.join(output_root, project)
    end

    def compose_path
      File.join(output_dir, 'compose.yaml')
    end

    def nginx_path
      File.join(output_dir, 'nginx.conf')
    end

    def image(service)
      images.fetch(service)
    end

    def url(app)
      "http://localhost:#{port}#{app.mount}"
    end

    def find_app(name)
      apps.find { |app| app.name == name }
    end
  end
end
