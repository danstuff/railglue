# frozen_string_literal: true

require_relative '../test_helper'

class ComposeTest < Minitest::Test
  def setup
    @config = TestConfig.build
    @compose = Railglue::Compose.build(@config)
    @services = @compose['services']
  end

  def test_one_service_per_app_and_database
    assert_equal %w[nginx shop admin blog postgres redis mysql],
                 @services.keys
    assert_equal 'railglue', @compose['name']
  end

  def test_sqlite_only_adds_no_database_service
    apps = [{ 'name' => 'a', 'database' => 'sqlite3' }]
    services = Railglue::Compose.build(TestConfig.build(apps: apps))
    assert_equal %w[nginx a], services['services'].keys
  end

  def test_nginx_service
    nginx = @services['nginx']
    assert_equal ['127.0.0.1:3000:80'], nginx['ports']
    assert_equal %w[shop admin blog], nginx['depends_on']
    assert_includes nginx['volumes'].first, @config.nginx_path
  end

  def test_app_volumes
    assert_equal [
      "#{Railglue::ROOT}/apps/admin:/app", 'mise:/mise', 'bundle-admin:/bundle'
    ], @services['admin']['volumes']
  end

  def test_app_environment
    env = @services['blog']['environment']
    assert_equal '/news/blog', env['RAILGLUE_MOUNT_PATH']
    assert_equal '/news/blog', env['RAILS_RELATIVE_URL_ROOT']
    assert_equal '3000', env['PORT']
    assert_match %r{@mysql:3306/blog_development\z}, env['DATABASE_URL']
    assert_match %r{/blog_test\z}, env['RAILGLUE_TEST_DATABASE_URL']
  end

  def test_root_app_has_no_relative_url_root
    refute_includes @services['shop']['environment'].keys,
                    'RAILS_RELATIVE_URL_ROOT'
  end

  def test_apps_wait_for_healthy_database
    assert_equal({ 'mysql' => { 'condition' => 'service_healthy' } },
                 @services['blog']['depends_on'])
  end

  def test_redis_environment_only_when_enabled
    env = @services['admin']['environment']
    assert_equal 'redis://:railglue@redis:6379/2', env['REDIS_URL']
    assert_equal 'redis://:railglue@redis:6379/3',
                 env['RAILGLUE_TEST_REDIS_URL']
    refute_includes @services['shop']['environment'].keys, 'REDIS_URL'
  end

  def test_app_waits_for_every_backing_service
    assert_equal %w[postgres redis], @services['admin']['depends_on'].keys
  end

  def test_backing_services_publish_no_ports
    %w[postgres redis mysql].each do |name|
      refute @services[name].key?('ports'), name
    end
  end

  def test_apps_share_one_image
    images = %w[shop admin blog].map { |name| @services[name]['image'] }
    assert_equal ['railglue-app'], images.uniq
  end

  def test_named_volumes
    assert_equal %w[mise bundle-shop bundle-admin bundle-blog postgres
                    redis mysql], @compose['volumes'].keys
  end

  def test_render_is_valid_yaml
    rendered = Railglue::Compose.render(@config)
    assert rendered.start_with?(Railglue::Compose::HEADER)
    assert_equal @compose, YAML.safe_load(rendered)
  end
end
