# frozen_string_literal: true

require_relative '../test_helper'

class DatabasesTest < Minitest::Test
  def app(database, name: 'my-app')
    Railglue::App.new(name: name, database: database)
  end

  def test_postgres_url
    assert_equal 'postgres://postgres:railglue@postgres:5432/my_app_test',
                 Railglue::Databases.url(app('postgresql'), 'test')
  end

  def test_mysql_urls_share_one_server
    assert_equal 'mysql2://root:railglue@mysql:3306/my_app_development',
                 Railglue::Databases.url(app('mysql2'), 'development')
    assert_match %r{\Atrilogy://root:railglue@mysql:3306/},
                 Railglue::Databases.url(app('trilogy'), 'test')
  end

  def test_sqlite_needs_no_server
    assert_nil Railglue::Databases.service_for(app('sqlite3'))
    assert_nil Railglue::Databases.url(app('sqlite3'), 'test')
  end

  def test_compose_service
    service = Railglue::Databases.compose_service('postgres', 'pg:1')
    assert_equal 'pg:1', service['image']
    assert_equal ['postgres:/var/lib/postgresql'], service['volumes']
    assert_equal 'railglue', service['environment']['POSTGRES_PASSWORD']
    assert_equal 'CMD', service['healthcheck']['test'].first
  end
end
