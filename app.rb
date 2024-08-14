# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require 'logger'

require 'bundler/setup'
Bundler.require 'default', ENV['RACK_ENV']

require './lib/dotenv'
require_relative './lib/github/project'

require 'active_record'
require_relative './models/issue'
require_relative './models/issues_sprint'
require_relative './models/sprint'

# The App
class App < Sinatra::Base
  def self.boot
    url = ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection url
  end

  def self.logger
    @@logger ||= Logger.new $stdout # rubocop:disable Style/ClassVars
  end

  get '/' do
    @title = 'Sprint Report'
    @sprints = Sprint.order(start_date: :desc)
    erb :index
  end

  get '/:id' do
    @sprint = Sprint.find(params[:id])
    @title = @sprint.title
    @breadcrumbs = [
      { title: 'Reports', path: '/' },
      { title: @sprint.title }
    ]
    erb :show
  end
end

App.boot
