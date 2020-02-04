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

get '/round_1/yearly_meals.js' do
  meals = CouchDB::get(CouchDB::uri("_design/round_1/_view/all_meals"))
  @years = Hash.new
  meals[:rows]&.each do |obj|
    # obj is a Hash with the following keys:
    #   _id: the document ID
    #   key: an array of date component strings, which should be [year, month, day]
    #   value: number of meals served

    # Parse out all the bits for readability, clarity, and DRYness.
    year = obj[:key][0]
    month = Integer(obj[:key][1], 10) - 1   # In JS, months range from 0 through 11.
    day = obj[:key][2]
    number_served = obj[:value]

    # Render a line of text for the current entry.
    # Note: we hard-code a year so that Highcharts will render all lines over one another; Highcharts doesn't know
    # how to make a "yearly" chart, just a "datetime" chart. This follows the example "Time data with irregular
    # intervals": https://www.highcharts.com/demo/spline-irregular-time
    #
    # We MUST use a leap year to ensure that February 29 is a valid date.
    entry = "          [Date.UTC(2020, #{month}, #{day}, 17, 30, 0), #{number_served}]"

    # Either instantiate or add to the year's array of values.
    if @years.has_key? year
      @years[year] << entry
    else
      @years[year] = [entry]
    end
  end

  # "Hashes enumerate their values in the order that the corresponding keys were inserted," which might require
  # us to sort the keys manually and iterate in that order, except that CouchDB stores its views in sorted order,
  # guaranteeing that we'll process our data sequentially. We can skip the sorting, but using SQLite3 in production
  # might require sorting, so future Dylan beware! :)
  #
  # Similarly, because of the sorting, we can easily pick out the final year from the keys.
  @latest_year = @years.keys.last.to_i  # Use to_i, not Integer(), to fail relatively gracefully. Should never fail.

  erb :'round_1/yearly_meals.js', content_type: 'application/javascript'
end

get '/round_1/monthly_meals_in_last_year.js' do
  meals = CouchDB::get(CouchDB::uri("_design/round_1/_view/all_meals"))
  @years = Hash.new
  meals[:rows]&.each do |obj|
    # obj is a Hash with the following keys:
    #   _id: the document ID
    #   key: an array of date component strings, which should be [year, month, day]
    #   value: number of meals served

    # Parse out all the bits for readability, clarity, and DRYness.
    year = obj[:key][0]
    month = Integer(obj[:key][1], 10) - 1   # In JS, months range from 0 through 11.
    day = obj[:key][2]
    number_served = obj[:value]

    # Render a line of text for the current entry.
    # Note: we hard-code a year so that Highcharts will render all lines over one another; Highcharts doesn't know
    # how to make a "yearly" chart, just a "datetime" chart. This follows the example "Time data with irregular
    # intervals": https://www.highcharts.com/demo/spline-irregular-time
    #
    # We MUST use a leap year to ensure that February 29 is a valid date.
    entry = "          [Date.UTC(2020, #{month}, #{day}, 17, 30, 0), #{number_served}]"

    # Either instantiate or add to the year's array of values.
    if @years.has_key? year
      @years[year] << entry
    else
      @years[year] = [entry]
    end
  end

  # "Hashes enumerate their values in the order that the corresponding keys were inserted," which might require
  # us to sort the keys manually and iterate in that order, except that CouchDB stores its views in sorted order,
  # guaranteeing that we'll process our data sequentially. We can skip the sorting, but using SQLite3 in production
  # might require sorting, so future Dylan beware! :)
  #
  # Similarly, because of the sorting, we can easily pick out the final year from the keys.
  @latest_year = @years.keys.last.to_i  # Use to_i, not Integer(), to fail relatively gracefully. Should never fail.

  erb :'round_1/monthly_meals_in_last_year.js', content_type: 'application/javascript'
end
