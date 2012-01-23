require 'open-uri'
require 'json'
require 'pp'

query = ARGV.shift                  # get a filename from the command line arguments
unless query                        # we can't work without a filename
  puts "no search query specified!"
  exit
end

BASE_URL = "http://search.twitter.com/search.json?q="     # remote API url
query_url = BASE_URL + URI.escape(query)                  # putting the 2 together

object = open(query_url) do |v|                                     # call the remote API
  input = v.read                                                    # read the full response
  #puts input                                                       # un-comment this to see the returned JSON magic
  JSON.parse(input)
  end
  object["results"].each do |result|
    puts result["text"]
end
