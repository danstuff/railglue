# frozen_string_literal: true

require_relative '../test_helper'

class DatabasesTest < Minitest::Test
  def app(database, name: 'my-app', redis: false, index: 0)
    Railglue::App.new(name: name, database: database, redis: redis,
                      index: index)
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

  def test_services_for
    assert_equal %w[postgres redis],
                 Railglue::Databases.services_for(app('postgresql',
                                                      redis: true))
    assert_equal [], Railglue::Databases.services_for(app('sqlite3'))
  end

  def test_redis_urls_give_each_app_and_env_its_own_db
    third = app('sqlite3', redis: true, index: 2)
    assert_equal 'redis://:railglue@redis:6379/4',
                 Railglue::Databases.redis_url(third, 'development')
    assert_equal 'redis://:railglue@redis:6379/5',
                 Railglue::Databases.redis_url(third, 'test')
  end

  def test_redis_has_enough_databases_for_every_app
    command = Railglue::Databases::SERVICES['redis']['command']
    count = Integer(command[command.index('--databases') + 1])
    last = app('sqlite3', index: Railglue::MAX_APPS - 1)
    last_db = Integer(Railglue::Databases.redis_url(last, 'test')[/\d+\z/])
    assert_operator last_db, :<, count
  end

  def test_redis_service_requires_password
    service = Railglue::Databases.compose_service('redis', 'redis:8')
    assert_includes service['command'], '--requirepass'
    refute service.key?('environment')
  end

  def test_compose_service
    service = Railglue::Databases.compose_service('postgres', 'pg:1')
    assert_equal 'pg:1', service['image']
    assert_equal ['postgres:/var/lib/postgresql'], service['volumes']
    assert_equal 'railglue', service['environment']['POSTGRES_PASSWORD']
    assert_equal 'CMD', service['healthcheck']['test'].first
  end
end
