# frozen_string_literal: true

require_relative 'helper'

# Every app in the config boots and serves its homepage at its mount.
class EnvironmentTest < Minitest::Test
  def setup
    E2E.boot unless E2E.config.apps.empty?
  end

  def test_config_has_apps
    skip "no apps in #{E2E::CONFIG_PATH}" if E2E.config.apps.empty?
  end

  E2E.config.apps.each do |app|
    define_method("test_#{app.name}_homepage") do
      E2E.urls_for(app).each do |url|
        response = E2E.wait_for_ok(url)
        assert_equal '200', response&.code, "#{url} (see bin/railglue logs)"
        assert_equal app.name, response['X-Railglue-App'], url
        assert_match %r{\Atext/html}, response['Content-Type'], url
      end
    end
  end
end
