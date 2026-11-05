ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rspec/rails"
require "capybara/rspec"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.before(type: :system) { driven_by :selenium, using: :headless_chrome }
end
