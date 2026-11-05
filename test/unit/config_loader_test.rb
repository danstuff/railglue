# frozen_string_literal: true

require_relative '../test_helper'

class ConfigLoaderTest < Minitest::Test
  def parse(**options)
    TestConfig.build(**options)
  end

  def assert_invalid(message, **options)
    error = assert_raises(Railglue::ConfigError) { parse(**options) }
    assert_match message, error.message
  end

  def app(overrides)
    { 'name' => 'x', 'database' => 'sqlite3' }.merge(overrides)
  end

  def test_defaults
    config = parse
    assert_equal 'railglue', config.project
    assert_equal 3000, config.port
    assert_equal 'postgres:18', config.image('postgres')
  end

  def test_app_defaults
    admin = parse.find_app('admin')
    assert_equal '/admin', admin.mount
    assert_equal File.join(Railglue::ROOT, 'apps/admin'), admin.path
  end

  def test_image_override
    config = parse(images: { 'postgres' => 'postgres:16' })
    assert_equal 'postgres:16', config.image('postgres')
    assert_equal 'mysql:8.4', config.image('mysql')
  end

  def test_empty_file_means_no_apps
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'railglue.yml')
      File.write(path, '')
      assert_empty Railglue::ConfigLoader.load(path).apps
    end
  end

  def test_missing_file
    error = assert_raises(Railglue::ConfigError) do
      Railglue::ConfigLoader.load('/nonexistent/railglue.yml')
    end
    assert_match 'not found', error.message
  end

  def test_unknown_keys
    assert_invalid 'unknown key(s) in config: extra', extra: 1
    assert_invalid 'apps[0]: colour', apps: [app('colour' => 'red')]
    assert_invalid 'unknown key(s) in images', images: { 'redis' => 'r' }
  end

  def test_bad_names
    assert_invalid 'name must match', apps: [app('name' => 'Bad')]
    assert_invalid 'name must match', apps: [app('name' => nil)]
    assert_invalid 'reserved', apps: [app('name' => 'postgres')]
  end

  def test_bad_mounts
    %w[admin /admin/ // /a?b].each do |mount|
      assert_invalid 'mount must', apps: [app('mount' => mount)]
    end
  end

  def test_bad_database
    assert_invalid 'database must be one of', apps: [app('database' => 'x')]
  end

  def test_database_defaults_to_postgresql
    assert_equal 'postgresql', parse.find_app('admin').database
  end

  def test_duplicates
    assert_invalid 'duplicate app name: a_b',
                   apps: [app('name' => 'a-b'), app('name' => 'a_b')]
    assert_invalid 'duplicate app mount: /',
                   apps: [app('name' => 'a', 'mount' => '/'),
                          app('name' => 'b', 'mount' => '/')]
  end

  def test_bad_top_level_values
    assert_invalid 'port must', port: 70_000
    assert_invalid 'port must', port: '80'
    assert_invalid 'project must', project: 'My Project'
    assert_invalid 'apps must be a list', apps: {}
  end

  def test_app_limit
    apps = Array.new(Railglue::MAX_APPS + 1) { |i| app('name' => "a#{i}") }
    assert_invalid 'at most', apps: apps
  end
end
