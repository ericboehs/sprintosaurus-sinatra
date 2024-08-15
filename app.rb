# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require 'sinatra/content_for'
require 'logger'

require 'bundler/setup'
Bundler.require 'default', ENV['RACK_ENV']

require './lib/dotenv'
require_relative './lib/github/project'

require 'active_record'
require_relative './models/issue'
require_relative './models/issues_sprint'
require_relative './models/project'
require_relative './models/sprint'

# The App
class App < Sinatra::Base
  helpers Sinatra::ContentFor

  def self.boot
    url = ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection url
  end

  def self.logger
    @@logger ||= Logger.new $stdout # rubocop:disable Style/ClassVars
  end

  get '/' do
    @title = 'Projects'
    @projects = Project.all
    erb :projects
  end

  get '/projects/:id' do
    @project = Project.find(params[:id])
    @title = @project.title
    @breadcrumbs = [
      { title: 'Projects', path: '/' },
      { title: @project.title&.truncate(20) }
    ]
    @sprints = @project.sprints
    erb :project
  end

  get '/sprints/:id' do
    @sprint = Sprint.find(params[:id])
    @title = @sprint.title
    @breadcrumbs = [
      { title: 'Projects', path: '/' },
      { title: @sprint.project.title, path: "/projects/#{@sprint.project.id}" },
      { title: @sprint.title }
    ]
    erb :sprint
  end
end

App.boot
