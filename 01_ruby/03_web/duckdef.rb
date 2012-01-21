require 'open-uri'
require 'json'
require 'pp'

query = ARGV.shift                  # get a query from the command line arguments
unless query                        # we can't work without a query
  puts "no search query specified!"
  exit
end

BASE_URL = "http://api.duckduckgo.com/?format=json&pretty=1&q="     # remote API url
# query     = "web services"                                          # query string
query_url = BASE_URL + URI.escape(query)                            # putting the 2 together

object = open(query_url) do |v|                                     # call the remote API
  input = v.read                                                    # read the full response
  #puts input                                                       # un-comment this to see the returned JSON magic
  JSON.parse(input)                                                 # parse the JSON & return it from the block
end

puts "#{object['Definition']}"