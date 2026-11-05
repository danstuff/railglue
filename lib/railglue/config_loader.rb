# frozen_string_literal: true

require 'yaml'

module Railglue
  # Reads railglue.yml and turns it into a validated Config.
  module ConfigLoader
    TOP_KEYS = %w[project port images apps].freeze
    APP_KEYS = %w[name path mount database redis].freeze
    PROJECT_FORMAT = /\A[a-z0-9][a-z0-9_-]{0,62}\z/.freeze
    NAME_FORMAT = /\A[a-z][a-z0-9_-]{0,30}\z/.freeze
    MOUNT_FORMAT = %r{\A/([A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*)?\z}.freeze
    RESERVED_NAMES =
      (%w[nginx mise] + Databases::SERVICES.keys).freeze

    module_function

    def load(path, output_root: DEFAULT_OUTPUT_ROOT)
      parse(read_yaml(path), output_root: output_root)
    end

    def read_yaml(path)
      YAML.safe_load(File.read(path), filename: path) || {}
    rescue Errno::ENOENT
      raise ConfigError, "config file not found: #{path}"
    rescue Psych::SyntaxError => e
      raise ConfigError, e.message
    end

    def parse(raw, output_root: DEFAULT_OUTPUT_ROOT)
      check_keys(raw, TOP_KEYS, 'config')
      config = Config.new(
        project: raw.fetch('project', 'railglue'),
        port: raw.fetch('port', 3000),
        images: parse_images(raw.fetch('images', {})),
        apps: parse_apps(raw.fetch('apps', [])),
        output_root: output_root
      )
      validate(config)
    end

    def check_keys(hash, allowed, context)
      raise ConfigError, "#{context} must be a mapping" unless hash.is_a?(Hash)

      unknown = hash.keys - allowed
      return if unknown.empty?

      raise ConfigError, "unknown key(s) in #{context}: #{unknown.join(', ')}"
    end

    def parse_images(raw)
      check_keys(raw, DEFAULT_IMAGES.keys, 'images')
      raw.each do |service, image|
        next if image.is_a?(String) && !image.empty?

        raise ConfigError, "images.#{service} must be an image name"
      end
      DEFAULT_IMAGES.merge(raw)
    end

    def parse_apps(list)
      raise ConfigError, 'apps must be a list' unless list.is_a?(Array)
      raise ConfigError, "at most #{MAX_APPS} apps" if list.size > MAX_APPS

      list.each_with_index.map { |raw, index| parse_app(raw, index) }
    end

    def parse_app(raw, index)
      check_keys(raw, APP_KEYS, "apps[#{index}]")
      name = check_name(raw['name'], index)
      App.new(
        name: name,
        path: File.expand_path(raw.fetch('path', "apps/#{name}"), ROOT),
        mount: raw.fetch('mount', "/#{name}"),
        database: raw.fetch('database', 'postgresql'),
        redis: raw.fetch('redis', false),
        index: index
      )
    end

    def check_name(name, index)
      return name if name.is_a?(String) && NAME_FORMAT.match?(name)

      raise ConfigError,
            "apps[#{index}].name must match #{NAME_FORMAT.source}"
    end

    def validate(config)
      check_project(config.project)
      check_port(config.port)
      config.apps.each { |app| check_app(app) }
      check_unique(config.apps.map { |app| app.name.tr('-', '_') }, 'name')
      check_unique(config.apps.map(&:mount), 'mount')
      config
    end

    def check_project(project)
      return if project.is_a?(String) && PROJECT_FORMAT.match?(project)

      raise ConfigError, "project must match #{PROJECT_FORMAT.source}"
    end

    def check_port(port)
      return if port.is_a?(Integer) && port.between?(1, 65_535)

      raise ConfigError, 'port must be an integer from 1 to 65535'
    end

    def check_app(app)
      if RESERVED_NAMES.include?(app.name)
        raise ConfigError, "#{app.name}: name is reserved"
      end
      unless app.mount.is_a?(String) && MOUNT_FORMAT.match?(app.mount)
        raise ConfigError, "#{app.name}: mount must look like / or /a/b"
      end
      unless Databases::ENGINES.key?(app.database)
        raise ConfigError, "#{app.name}: database must be one of " \
                           "#{Databases::ENGINES.keys.join(', ')}"
      end
      return if [true, false].include?(app.redis)

      raise ConfigError, "#{app.name}: redis must be true or false"
    end

    def check_unique(values, field)
      duplicates = values.select { |value| values.count(value) > 1 }.uniq
      return if duplicates.empty?

      raise ConfigError, "duplicate app #{field}: #{duplicates.join(', ')}"
    end
  end
end
