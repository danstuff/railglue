# frozen_string_literal: true

require_relative 'helper'

# Extra checks that rely on the fixture apps in test/fixtures/apps.
class FixtureTest < Minitest::Test
  def setup
    skip 'run with rake test:fixtures' unless ENV['RAILGLUE_E2E_FIXTURES']
    E2E.boot
  end

  def each_homepage
    E2E.config.apps.each do |app|
      yield app, E2E.wait_for_ok(E2E.config.url(app)).body
    end
  end

  def test_links_include_mount_path
    each_homepage do |app, body|
      root = app.root? ? '/' : "#{app.mount}/"
      assert_includes body, %(href="#{root}"), app.name
    end
  end

  def test_each_app_has_its_own_database
    each_homepage do |app, body|
      assert_includes body, app.database_name('development'), app.name
    end
  end

  def test_rspec_passes_in_each_app
    E2E.config.apps.each do |app|
      assert_equal 0, E2E.cli('rspec', app.name), "rspec failed: #{app.name}"
    end
  end
end
