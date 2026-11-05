# frozen_string_literal: true

module Railglue
  # Shared database servers and the Rails adapters that connect to them.
  module Databases
    PASSWORD = 'railglue'
    REDIS_ENVS = %w[development test].freeze

    SERVICES = {
      'postgres' => {
        'user' => 'postgres',
        'port' => 5432,
        'data' => '/var/lib/postgresql',
        'environment' => { 'POSTGRES_PASSWORD' => PASSWORD },
        'healthcheck' => %w[CMD pg_isready -U postgres]
      },
      'mysql' => {
        'user' => 'root',
        'port' => 3306,
        'data' => '/var/lib/mysql',
        'environment' => { 'MYSQL_ROOT_PASSWORD' => PASSWORD },
        'healthcheck' =>
          %W[CMD mysqladmin ping -h 127.0.0.1 -uroot -p#{PASSWORD}]
      },
      'redis' => {
        'port' => 6379,
        'data' => '/data',
        'command' => %W[redis-server --requirepass #{PASSWORD}
                        --databases #{MAX_APPS * REDIS_ENVS.size}],
        'healthcheck' => %W[CMD redis-cli --no-auth-warning -a #{PASSWORD}
                            ping]
      }
    }.freeze

    ENGINES = {
      'postgresql' => { 'service' => 'postgres', 'scheme' => 'postgres' },
      'mysql2' => { 'service' => 'mysql', 'scheme' => 'mysql2' },
      'trilogy' => { 'service' => 'mysql', 'scheme' => 'trilogy' },
      'sqlite3' => { 'service' => nil, 'scheme' => nil }
    }.freeze

    module_function

    def service_for(app)
      ENGINES.fetch(app.database)['service']
    end

    def services_for(app)
      [service_for(app), app.redis ? 'redis' : nil].compact
    end

    def redis_url(app, env)
      number = app.index * REDIS_ENVS.size + REDIS_ENVS.index(env)
      "redis://:#{PASSWORD}@redis:#{SERVICES['redis']['port']}/#{number}"
    end

    def url(app, env)
      engine = ENGINES.fetch(app.database)
      return nil unless engine['service']

      server = SERVICES.fetch(engine['service'])
      "#{engine['scheme']}://#{server['user']}:#{PASSWORD}@" \
        "#{engine['service']}:#{server['port']}/#{app.database_name(env)}"
    end

    def compose_service(name, image)
      server = SERVICES.fetch(name)
      {
        'image' => image,
        'command' => server['command'],
        'environment' => server['environment'],
        'volumes' => ["#{name}:#{server['data']}"],
        'healthcheck' => healthcheck(server['healthcheck'])
      }.compact
    end

    def healthcheck(test)
      { 'test' => test, 'interval' => '2s', 'timeout' => '5s', 'retries' => 60 }
    end
  end
end
