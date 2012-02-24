
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
  attributes :category, :text
  validates_presence_of :category, :text
  belongs_to :inventor
end

# find_by_attribute(inventorID)
class Inventor < SuperModel::Base
  attributes :name
  validates :name, :presence => true, :uniqueness => true
end

  
class RestfulServer < Sinatra::Base
  ANON = Inventor.create!(:name => "ANONYMOUS")
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

  def bad_request
    status 400
    body "bad request\n"
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
    givenInv = jsonData["inventor"]

    # If no inventor is given, assign the anon inventor
    if givenInv.nil?
      inv = ANON
      
    # Check the id and name of the given inventor
    else
      # If the inventor is given and it already is stored, associate it
      # If only contains name, if it doesn't exist, create one
      if Inventor.exists?(givenInv["id"])
        # The inventor id exists, associate it
        inv = Inventor.find(givenInv["id"])
        
      elsif !Inventor.find_by_name(givenInv["name"]).nil?
        # The inventor name exists, associate it
        inv = Inventor.find_by_name(givenInv["name"])
      
      else
        # The inventor was given and does not exist, create it
        inv = Inventor.new(givenInv)
        begin
          inv.save!
        rescue
          puts "Failed to save inventor, no name"
          bad_request
        end
      end
    end
    
    jsonData.delete("inventor")
    
      idea = Idea.new(jsonData)
      idea.inventor = inv
    begin
      idea.save!
    rescue
      puts "Failed to save idea, no category/text"
      bad_request
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
    begin
      idea.update_attributes!(JSON.parse(request.body.read))
    rescue
      puts "Failed to update idea, no category/text"
      bad_request
    end
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
  
  # delete all ideas and inventors
  post '/nuke' do
    password = params[:message]
    if password == "yesireallymeanit"
      Idea.destroy_all
      Inventor.destroy_all
    end
  end
  
  run! if app_file == $0
end