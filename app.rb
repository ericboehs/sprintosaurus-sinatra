# frozen_string_literal: true

require_relative './environment'

# The App
class App < Sinatra::Base
  include ActionView::Helpers::DateHelper
  helpers Sinatra::ContentFor

  get '/' do
    @title = 'Projects'
    @projects = Project.all
    erb :projects
  end

  get '/projects/new' do
    @project = Project.new
    erb :new_project
  end

  post '/projects' do
    project = Project.new(url: params[:url])
    project.number = project.url.match(%r{github.com/orgs/[^/]+/projects/(\d+)}).captures.first
    project.title = "Pending Sync for #{project.number}"
    project.save!
    redirect "/projects/#{project.id}"
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
