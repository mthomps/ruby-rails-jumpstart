
filename = ARGV.shift                   # get a filename from the command line arguments

unless filename                         # we can't work without a filename
  puts "no filename specified!"
  exit
end

lines = 0                               # a humble line counter
# hash naming convention?
user_activity_hash = {}                 # username : # of pageloads
url_hitcount_hash = {}                  # url : total # of hits
date_activity_hash = {}                 # date : # of hits on that date
url_uniques_hash = {}                   # url : {user : user}

open(filename).each do |m|              # loop over every line of the file
  lines += 1                            # bump the counter
  next if lines == 1                    # ignore the header line, skip to the next line
  m.chomp!                              # remove the trailing newline
  values = m.split(",")                 # split comma-separated fields into a values array
  date, userID, url = values[0], values[1], values[2]
  
  # cleaner with ternary operators?  
  if user_activity_hash[userID].nil? # update the hash of {user : pagecount}
    user_activity_hash[userID] = 0
  else
    user_activity_hash[userID] += 1
  end
  
  if url_hitcount_hash[url].nil?      # update the hash of {url : hitcount}
    url_hitcount_hash[url] = 0
  else
    url_hitcount_hash[url] += 1
  end
  
  if date_activity_hash[date].nil?   # update the hash of {date : activity}
    date_activity_hash[date] = 0
  else
    date_activity_hash[date] += 1
  end
  
  if url_uniques_hash[url].nil?       # update the hash of {url : {user : hitcount}}
    url_uniques_hash[url] = { userID => 1 }
  elsif (url_uniques_hash[url][userID].nil?)
    url_uniques_hash[url][userID] = 1
  else
    url_uniques_hash[url][userID] += 1
  end
end

puts "total lines: #{lines - 1}"            # output stats (excludes the header line)
puts "unique users: #{user_activity_hash.length}" 
puts "unique pages: #{url_hitcount_hash.length}"
# sort the hashes, select the last item (because we want "most"), retrieve the key(at [0])
unless lines <= 1                           # prevent crash when log file is empty
  puts "most active day: #{date_activity_hash.sort_by { |date, activity| activity }.last[0]}" 
  puts "most active user: #{user_activity_hash.sort_by { |user, activity| activity }.last[0]}" 
  puts "most active page: #{url_hitcount_hash.sort_by { |url, hitcount| hitcount }.last[0]}" 
  puts "most popular page (by unique users): #{url_uniques_hash.sort_by { |url, userlist| userlist.length }.last[0]}"
end