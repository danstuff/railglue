class HomeController < ApplicationController
  def index
    @database = ActiveRecord::Base.connection.current_database
  end
end
