# frozen_string_literal: true

require_relative './environment'
require_relative './job'

# The App
class App < Sinatra::Base
  include ActionView::Helpers::DateHelper
  helpers Sinatra::ContentFor

  get '/' do
    @projects = Project.all
    erb :projects
  end

  get '/projects/new' do
    @project = Project.new
    erb :new_project
  end

  post '/projects' do
    number = params['url'].match(%r{github.com/orgs/[^/]+/projects/(\d+)}).captures.first
    project = Project.find_by(number:)
    project ||= Project.create(title: "Pending Sync for #{number}", number:, url: params['url'])
    redirect "/projects/#{project.id}"
  end

  get '/projects/:id' do
    @project = Project.find(params[:id])
    @title = @project.title
    @breadcrumbs = [
      { title: 'Projects', path: '/' },
      { title: @project.title&.truncate(20) }
    ]

    @page = (params[:page] || 1).to_i
    @per_page = 5
    @sprints = @project.sprints
    if params[:status] == 'completed'
      @sprints = @sprints.where("(start_date + duration * INTERVAL '1 day') < ?", Time.now).order(start_date: :desc)
    else
      @sprints = @sprints.where("(start_date + duration * INTERVAL '1 day') > ?", Time.now).order(start_date: :asc)
    end
    @total_items = @sprints.count
    @sprints = @sprints.limit(@per_page).offset((@page - 1) * @per_page)
    @total_pages = (@total_items / @per_page.to_f).ceil

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
