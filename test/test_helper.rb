# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/railglue'

# Builders shared by the unit tests.
module TestConfig
  APPS = [
    { 'name' => 'shop', 'mount' => '/', 'database' => 'postgresql' },
    { 'name' => 'admin', 'redis' => true },
    { 'name' => 'blog', 'mount' => '/news/blog', 'database' => 'mysql2' }
  ].freeze

  module_function

  def raw(apps: APPS, **top)
    { 'apps' => apps }.merge(top.transform_keys(&:to_s))
  end

  def build(output_root: Dir.tmpdir, **options)
    Railglue::ConfigLoader.parse(raw(**options), output_root: output_root)
  end

  def with_app_dirs(config)
    config.apps.each do |app|
      FileUtils.mkdir_p(app.path)
      File.write(File.join(app.path, 'Gemfile'), '')
    end
    config
  end

  def app_entries(root)
    APPS.map { |app| app.merge('path' => File.join(root, app['name'])) }
  end
end
