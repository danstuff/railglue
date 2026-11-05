# frozen_string_literal: true

require 'net/http'
require_relative '../test_helper'

# Boots the configured environment once and polls it over HTTP.
module E2E
  CONFIG_PATH = ENV.fetch('RAILGLUE_CONFIG', Railglue::DEFAULT_CONFIG)
  BOOT_TIMEOUT = 1800 # seconds; the first boot installs Ruby and gems
  POLL_INTERVAL = 5
  NETWORK_ERRORS = [SystemCallError, IOError, Net::OpenTimeout,
                    Net::ReadTimeout].freeze

  module_function

  def config
    @config ||= Railglue::ConfigLoader.load(CONFIG_PATH)
  end

  def cli(*args)
    Railglue::CLI.new.run(['--config', CONFIG_PATH, *args])
  end

  def boot
    @boot_status ||= start
    raise 'docker compose up failed' unless @boot_status == :up
  end

  def start
    return :failed unless cli('up', '-d', '--build').zero?

    Minitest.after_run { cli('down') unless ENV['RAILGLUE_E2E_KEEP'] }
    :up
  end

  def wait_for_ok(url)
    (BOOT_TIMEOUT / POLL_INTERVAL).times do
      response = get(url)
      return response if response&.code == '200'

      sleep POLL_INTERVAL
    end
    get(url)
  end

  def get(url)
    Net::HTTP.get_response(URI(url))
  rescue *NETWORK_ERRORS
    nil
  end

  def urls_for(app)
    url = config.url(app)
    app.root? ? [url] : [url, "#{url}/"]
  end
end
