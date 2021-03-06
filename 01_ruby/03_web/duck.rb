require 'open-uri'
require 'json'

api_url = ARGV.shift                   # get a query from the command line arguments
unless api_url                         # exit if we don't get one
  puts "no query specified!"
  exit
end

BASE_URL = "http://api.duckduckgo.com/?format=json&pretty=1&q="     # remote API url
query     = "web services"                                          # query string
query_url = BASE_URL + URI.escape(query)                            # putting the 2 together


puts " ======================================== "                   # fancy output
puts "   #{query_url}"                                              # fancy output

object = open(query_url) do |v|                                     # call the remote API
  input = v.read                                                    # read the full response
  puts input                                                       # un-comment this to see the returned JSON magic
  JSON.parse(input)                                                 # parse the JSON & return it from the block
end

puts " ======================================== "                   # fancy output
puts "   #{object['Heading']}"
puts "     #{object['Abstract']}"
puts "     #{object['AbstractURL']}"
puts " ---------------------------------------- "

object['RelatedTopics'].each do |rt|                                # processing sub-elements
  puts
  puts "   * #{rt['Text']}"
  puts "     #{rt['FirstURL']}"
end

puts                                                                # fancy output
puts " ---------------------------------------- "
puts " ======================================== "