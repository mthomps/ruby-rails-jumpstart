
require 'bundler/setup'
require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'supermodel'
require 'json'
require 'open-uri'
require 'people_places_things'
include PeoplePlacesThings

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
  validate do |inventor|
    puts "SHIT!"
    json_result = inventor.gender_detect
    status = json_result["status"]
    gender_result = json_result["answer"]
    puts gender_result
    probability = json_result["likelihood"]
    if inventor.gender.nil? or (status.casecmp("NOT FOUND") == 0)
      puts "no gender or rapleaf gender detection failed"
      return
    elsif ((gender_result["gender"].casecmp(inventor.gender) == 0) && probability.to_f >= 0.8) 
      puts "gender matches, probability is >80%"
      return
    else
      # ActiveRecord::RecordInvalid?
      # Adding an error here, how to rescue it later?
      puts "gender does NOT match name!! raise and error!"
      raise InvalidRecord, "blah", caller
      inventor.errors[:gender] << "Invalid record: gender should match name"
    end
  end
  validate :gender_matches_name, :on => :save
  attributes :name, :gender
  validates :name, :presence => true, :uniqueness => true
  validates :gender, :presence => true
  
  def first_name
    person_name = PersonName.new(self.name)
    if person_name.first.nil?
      self.name
    else
      person_name.first
    end
  end
  
  def last_name
    person_name = PersonName.new(self.name)
    person_name.last
  end
  
  def gender_matches_name

  end
  
  # given a name, returns rapleaf gender guess JSON object
  def gender_detect
    base_url = "https://www.rapleaf.com/developers/try_name_to_gender?query="
    query_url = base_url + URI.escape(self.first_name)
    object = open(query_url) do |v|
      input = v.read
      JSON.parse(input)
    end
    object
  end
end
=begin
class genderValidator < ActiveModel::Validator
  def validate(inventor)
    puts "SHIT!"
    json_result = self.gender_detect
    status = json_result["status"]
    gender_result = json_result["answer"]
    probability = json_result["likelihood"]
    if self.gender.nil? or (status.casecmp("NOT FOUND") == 0)
      puts "no gender or rapleaf gender detection failed"
      return
    elsif ((gender_result["gender"].casecmp(self.gender) == 0) && probability.to_f >= 0.8) 
      puts "gender matches, probability is >80%"
      return
    else
      # ActiveRecord::RecordInvalid?
      # Adding an error here, how to rescue it later?
      puts "gender does NOT match name!! raise and error!"
      raise InvalidRecord, "blah", caller
      record.errors[:gender] << "Invalid record: gender should match name"
    end
  end  
end    
=end
class RestfulServer < Sinatra::Base
  ANON = Inventor.create!(:name => "ANONYMOUS", :gender => "male")
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
        rescue Exception => e
          puts "Failed to save inventor, no name"
          puts e.message
          bad_request
        end
      end
    end
    
    jsonData.delete("inventor")
    
      idea = Idea.new(jsonData)
      idea.inventor = inv
    begin
      idea.save!
    rescue Exception => e
      puts "Failed to save idea, no category/text"
      puts e.message
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
    rescue Exception => e
      puts e.message
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