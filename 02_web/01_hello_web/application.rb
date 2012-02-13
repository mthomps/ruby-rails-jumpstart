
require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'json'
require 'roxml'
require 'yaml'
require 'lingua/stemmer'

class ExampleServer < Sinatra::Base
  CONTENT_TYPES = {
    'txt'  => 'text/plain',
    'yaml'  => 'text/plain',
    'xml'  => 'text/xml',
    'json' => 'application/json'
  }
  
  # FIXME: duplicate code between the method pairs
  # FIXME: figure out best way to parse format of request 
  # and return result in that format
  #
  # helper method that takes a ruby object and returns a string
  # representation in the specified format
  #
=begin
  def reformat(data)
    # seems a bit unsafe/weird
    format = params[:format] unless params[:format].nil?
    if format.nil?
      format = data[:message].split('.')[1]
      data[:message] = data[:message].split('.')[0]
    end
    format = "json" if format.nil?
    content_type CONTENT_TYPES[format], :charset => 'utf-8'
    case format
    when 'txt'
      data.to_s
    when 'yaml'
      YAML::dump(data)
    when 'xml'
      data.to_xml
    when 'json'
      data.to_json
    else
      raise 'Unknown format: ' + format
    end
  end
=end

  def reformat(data, format=params[:format])
      content_type CONTENT_TYPES[format], :charset => 'utf-8'
      case format
      when 'txt'
        data.to_s
      when 'yaml'
        YAML::dump(data)
      when 'xml'
        data.to_xml
      when 'json'
        data.to_json
      else
        raise 'Unknown format: ' + format
      end
    end
    
  
  #
  # helper method that takes a string and returns the piglatin translation
  #
  def piglatin(word)
    suffix = word[0] + "ay"
    word.slice!(0)
    word + suffix
  end

  #
  # helper method that takes a string and returns the stem using
  # ruby-stemmer
  #
  def stem(word)
    stemmer = Lingua::Stemmer.new
    stemmer.stem word
  end
  
  # a basic time service, a la:
  # http://localhost:4567/time.txt (or .xml or .json or .yaml)
  #
  get '/time.?:format?' do 
    reformat({ :time => Time.now })
  end

  #
  # outputs a message from the url as plain text,
  # a la : http://localhost:4567/echo/foo
  #
  get '/echo/:message' do
    content_type 'text/plain', :charset => 'utf-8'
    params[:message]
    #reformat({:message => params[:message]})
  end

  #
  # outputs a message from the url parameter as plain text,
  # a la : http://localhost:4567/echo?message=foo
  #
  get '/echo' do
    content_type 'text/plain', :charset => 'utf-8'
    params[:message]
    #reformat({:message => params[:message]})
  end

  # displays the reverses of the given message
  get '/reverse/:message' do
    content_type 'text/plain', :charset => 'utf-8'
    params[:message].reverse!
  end

  # displays the reverses of the given message
  get '/reverse' do
    content_type 'text/plain', :charset => 'utf-8'
    params[:message].reverse!
  end

# displays the message translated into pig latin
  get '/piglatin/:message' do
    content_type 'text/plain', :charset => 'utf-8'
    words = []
    (params[:message]).split.each do |word|
      words << piglatin(word) + " "
    end
    words
  end

# displays the message translated into pig latin
  get '/piglatin' do
    content_type 'text/plain', :charset => 'utf-8'
    words = []
    (params[:message]).split.each do |word|
      words << piglatin(word) + " "
    end
    words
  end

  # translates the message into a comma-separated list of 
  # tokens using the snowball stemming algorithm
  get '/snowball/:message' do
    content_type 'text/plain', :charset => 'utf-8'
    stems = []
    (params[:message]).split.each do |word|
      stems << stem(word) + " "
    end
    stems
  end

  # translates the message into a comma-separated list of 
  # tokens using the snowball stemming algorithm
  get '/snowball' do
    content_type 'text/plain', :charset => 'utf-8'
    stems = []
    (params[:message]).split.each do |word|
      stems << stem(word) + " "
    end
    stems
  end

  run! if app_file == $0
end