# frozen_string_literal: true

require_relative '../test_helper'

class NginxTest < Minitest::Test
  def render(**options)
    Railglue::Nginx.render(TestConfig.build(**options))
  end

  def test_prefixed_app_gets_prefix_and_exact_locations
    conf = render
    assert_includes conf, 'location ^~ /admin/ {'
    assert_includes conf, 'location = /admin {'
    assert_includes conf, 'set $upstream http://admin:3000;'
    assert_includes conf, 'add_header X-Railglue-App admin always;'
  end

  def test_root_app
    conf = render
    assert_includes conf, "location / {\n" \
                          "        set $upstream http://shop:3000;"
    refute_includes conf, 'return 404'
  end

  def test_longest_mount_first
    conf = render
    assert_operator conf.index('/news/blog/'), :<, conf.index('/admin/')
  end

  def test_404_without_root_app
    apps = [{ 'name' => 'a', 'database' => 'sqlite3' }]
    assert_includes render(apps: apps), 'return 404;'
  end

  def test_websocket_and_forwarding_headers
    conf = render
    assert_includes conf, 'resolver 127.0.0.11'
    assert_includes conf, 'proxy_set_header Connection $connection_upgrade;'
    assert_includes conf, 'proxy_set_header Host $http_host;'
  end

  def test_braces_balance
    conf = render
    assert_equal conf.count('{'), conf.count('}')
  end
end
