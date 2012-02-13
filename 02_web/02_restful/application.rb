
require 'bundler/setup'
require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'supermodel'
require 'json'

#
# For documentation, see:
#   https://github.com/maccman/supermodel/blob/master/lib/supermodel/base.rb
#
class Idea < SuperModel::Base
  include SuperModel::RandomID
  belongs_to :inventor
end

class Inventor < SuperModel::Base
  # has_many :ideas ?
  @@anonymous = Inventor.create(:name => "ANONYMOUS")
  def self.anon
    @@anonymous
  end
end

  
class RestfulServer < Sinatra::Base
  # helper method that returns json
  def json_out(data)
    content_type 'application/json', :charset => 'utf-8'
    data.to_json + "\n"
  end

  # displays a not found error
  def not_found
    status 404
    body "not found\n"
  end

  # obtain a list of all ideas
  def list_ideas
    json_out(Idea.all)
  end

  # display the list of ideas
  get '/' do
    list_ideas
  end

  # display the list of ideas
  get '/ideas' do
    list_ideas
  end
  
  # obtain a list of all inventors
  def list_inventors
    json_out(Inventor.all)
  end

  # display the list of inventors
  get '/inventors' do
    list_inventors
  end
  # create a new idea
  # FIXME: If an inventor isn't given, assign the anonymous,
  # if an inventor is given but is not stored yet, store it
  post '/ideas' do
    jsonData = JSON.parse(request.body.read)
    idea = Idea.create!(jsonData)
    if idea.inventor.nil?
      idea.inventor = Inventor.anon
      idea.save
    elsif !Inventor.exists?(jsonData[:inventor])
      inventor = Inventor.create!(jsonData[:inventor])
      inventor.save
    end
    json_out(idea)
  end

  # get an idea by id
  get '/ideas/:id' do
    unless Idea.exists?(params[:id])
      not_found
      return
    end

    json_out(Idea.find(params[:id]))
  end

  # update an idea
  put '/ideas/:id' do
    unless Idea.exists?(params[:id])
      not_found
      return
    end

    idea = Idea.find(params[:id])
    idea.update_attributes!(JSON.parse(request.body.read))
    json_out(idea)
  end

  # delete an idea
  delete '/ideas/:id' do
    unless Idea.exists?(params[:id])
      not_found
      return
    end

    Idea.find(params[:id]).destroy
    status 204
    "idea #{params[:id]} deleted\n"
  end

  # delete an inventor
  delete '/inventors/:id' do
    unless Inventor.exists?(params[:id])
      not_found
      return
    end

    Idea.find(params[:id]).destroy
    status 204
    "idea #{params[:id]} deleted\n"
  end
  
  run! if app_file == $0
end