require_relative '../db/lib/couchdb'
require 'sinatra'

set :public_folder, File.dirname(__FILE__) + '/static'

# Serve the landing page.
get '/' do
  send_file File.expand_path('index.html', settings.public_folder)
end

get '/_all_docs' do
  CouchDB::get(CouchDB::uri("_all_docs")).inspect
end

get '/round_1/all_meals.js' do
  meals = CouchDB::get(CouchDB::uri("_design/round_1/_view/all_meals"))
  meals = meals[:rows]&.map do |obj|
    # obj is a Hash with the following keys:
    #   _id: the document ID
    #   key: an array of date component strings, which should be [year, month, day]
    #   value: number of meals served

    year = obj[:key][0]
    month = Integer(obj[:key][1], 10) - 1   # In JS, months range from 0 through 11.
    day = obj[:key][2]
    number_served = obj[:value]
    "        [Date.UTC(#{year}, #{month}, #{day}, 17, 30, 0), #{number_served}]"
  end
  @data =
    if meals.nil?
      ""
    else
      meals.join(",\n")
    end

  erb :'round_1/all_meals.js', content_type: 'application/javascript'
end
