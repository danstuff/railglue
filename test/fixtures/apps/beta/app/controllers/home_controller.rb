class HomeController < ApplicationController
  def index
    @database = ActiveRecord::Base.connection.current_database
    redis = Redis.new
    @redis = "#{redis.ping} db#{redis.connection[:db]}"
  end
end
