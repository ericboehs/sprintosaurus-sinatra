# frozen_string_literal: true

require_relative './environment'
require_relative './job'
require 'secure_headers'

if ENV['RACK_ENV'] == 'production' || ENV['ENABLE_CSP'] == 'true'
  SecureHeaders::Configuration.default do |config|
    config.csp = {
      default_src: ["'self'"], # Allow resources from the same origin
      script_src: ["'self'", "sprintosaurus.com", "https://cdn.tailwindcss.com", "https://cdn.jsdelivr.net"], # Specify allowed JavaScript sources
      style_src: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com"], # Allow inline styles and TailwindCSS
      img_src: ["'self'", "data:"], # Allow images and base64 encoded images
      font_src: ["'self'", "https://fonts.googleapis.com", "https://cdn.tailwindcss.com"],
      connect_src: ["'self'", "https://sprintosaurus.com", "https://cdn.tailwindcss.com", "https://cdn.jsdelivr.net"], # Allow API requests
      object_src: ["'none'"], # Disallow Flash/other plugins
      frame_ancestors: ["'none'"], # Prevent clickjacking
      base_uri: ["'self'"],
      form_action: ["'self'"],
      upgrade_insecure_requests: true # Upgrade HTTP to HTTPS
    }
  end
end

# The App
class App < Sinatra::Base
  use SecureHeaders::Middleware if ENV['RACK_ENV'] == 'production' || ENV['ENABLE_CSP'] == 'true'
  include ActionView::Helpers::DateHelper
  helpers Sinatra::ContentFor
  helpers do
    def paginate(collection, page: 1, per_page: 10)
      total_items = collection.count
      paginated_collection = collection.limit(per_page).offset((page - 1) * per_page)
      total_pages = (total_items / per_page.to_f).ceil
      @total_pages = total_pages

      {
        collection: paginated_collection,
        total_pages:,
        total_items:,
        current_page: page,
        per_page:
      }
    end
  end

  set :public_folder, File.dirname(__FILE__) + '/public'

  get '/' do
    @projects = Project.all.order(updated_at: :desc)
    @paginated_projects = paginate(@projects, page: (params[:page] || 1).to_i)[:collection]
    erb :projects
  end

  get '/projects/new' do
    @title = 'New Project'
    @project = Project.new
    erb :new_project
  end

  post '/projects' do
    @title = 'Projects'
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
      { title: @project.title }
    ]

    @sprints = @project.sprints
    if params[:status] == 'completed'
      @sprints = @sprints.where("(start_date + duration * INTERVAL '1 day') < ?", Time.now).order(start_date: :desc)
    else
      @sprints = @sprints.where("(start_date + duration * INTERVAL '1 day') > ?", Time.now).order(start_date: :asc)
    end

    @paginated_sprints = paginate(@sprints, page: (params[:page] || 1).to_i)[:collection]
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

  get '/sprints/:id/csv' do
    @sprint = Sprint.find(params[:id])
    content_type 'application/csv'
    attachment "#{@sprint.title.gsub(/[^0-9A-Za-z.-]/, '_').downcase}.csv"
    @sprint.issues_to_csv
  end
end
