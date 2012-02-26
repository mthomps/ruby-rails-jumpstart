
require 'bundler/setup'
require 'rubygems'
require 'sinatra/base'
require 'sinatra/respond_to'
require 'padrino-helpers'
require 'rack/csrf'
require 'rack/methodoverride'
require 'supermodel'
require 'haml'
require 'json'

# ----------------------------------------------------
# models
# ----------------------------------------------------
class Location < SuperModel::Base
  include SuperModel::RandomID
  attributes :name, :lat, :lon
  validates :name, :presence => true
  validates_numericality_of :lat, :greater_than_or_equal_to => -90, :less_than_or_equal_to => 90
  validates_numericality_of :lon, :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180
end

class Query < SuperModel::Base
  include SuperModel::RandomID
  attributes :name, :text
  validates :name, :text, :presence => true
end

# ----------------------------------------------------
# web app
# ----------------------------------------------------
class Webby < Sinatra::Base
  register Sinatra::RespondTo # routes .html to haml properly
  register Padrino::Helpers # enables link and form helpers

  set :views, File.join(File.dirname(__FILE__), 'views') # views directory for haml templates
  set :public_directory, File.dirname(__FILE__) + 'public' # public web resources (images, etc)

  BASE_URL = "http://api.duckduckgo.com/?format=json&pretty=1&q="

  configure do # use rack csrf to prevent cross-site forgery
    use Rack::Session::Cookie, :secret => "in a real application we would use a more secure cookie secret"
    use Rack::Csrf, :raise => true
  end

  helpers do # csrf link/tag helpers
    def csrf_token
      Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
      Rack::Csrf.csrf_tag(env)
    end
  end

  # --- Core Web Application : index ---
  get '/' do
    haml :'index', :layout => :application
  end

  # --- Core Web Application : locations ---
  get '/locations/?' do
    @locations = Location.all
    haml :'locations/index', :layout => :application
  end

  get '/locations/new' do
    @location = Location.new
    haml :'locations/edit', :layout => :application
  end

  get '/locations/:id' do
    @location = Location.find(params[:id])
    haml :'locations/show', :layout => :application
  end

  get '/locations/:id/edit' do
    @location = Location.find(params[:id])
    @action = "/locations/#{params[:id]}/update"
    haml :'locations/edit', :layout => :application
  end

  post '/locations/?' do
    begin
      @location = Location.create!(params[:location])
      redirect to('/locations/' + @location.id)
    rescue Exception => e
      "post broke"
      puts e
    end
  end

  post '/locations/:id/update' do
    if @location = Location.find(params[:id])
      begin
        @location.update_attributes!(params[:location])
        redirect to('/locations/' + @location.id)
        haml :'locations/index', :layout => :application
      rescue Exception => e
        puts "update broke"
        puts e
      end
    end
  end

  post '/locations/:id/delete' do
    @location = Location.find(params[:id])
    @location.destroy
    redirect to('/locations')
  end

    # --- Core Web Application : About ---
  get '/about/?' do
    haml :'about/index', :layout => :application
  end

  # --- Core Web Application : duckduckgo queries ---

  #helper to get query results
  def duckduckgoResults(query)
    query_url = BASE_URL + URI.escape(query)
    object = open(query_url) do |v|
      input = v.read
      JSON.parse(input)
    end
    object
  end

  get '/duckduckgo/?' do
    @queries = Query.all
    haml :'duckduckgo/index', :layout => :application
  end

  get '/duckduckgo/new' do
    @query = Query.new
    haml :'duckduckgo/edit', :layout => :application
  end

  get '/duckduckgo/:id' do
    @query = Query.find(params[:id])
    haml :'duckduckgo/show', :layout => :application
  end

  get '/duckduckgo/:id/edit' do
    @query = Query.find(params[:id])
    @action = "/duckduckgo/#{params[:id]}/update"
    haml :'duckduckgo/edit', :layout => :application
  end

  post '/duckduckgo/?' do
    begin
      @query = Query.create!(params[:query])
      redirect to('/duckduckgo/' + @query.id)
    rescue Exception => e
      puts "The query post broke!"
      puts e
    end
  end

  post '/duckduckgo/:id/update' do
    if @query = Query.find(params[:id])
      begin
        @query.update_attributes!(params[:query])
        redirect to('/duckduckgo/' + @query.id)
        haml :'duckduckgo/index', :layout => :application
      rescue Exception => e
        puts "Update broke"
        puts e
      end
    end
  end

  post '/duckduckgo/:id/delete' do
    @query = Query.find(params[:id])
    @query.destroy
    redirect to('/duckduckgo')
  end

  # --- Core Web Application : twitter queries ---
  # TODO

  run! if app_file == $0
end