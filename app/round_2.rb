require 'sinatra/base'

class Round2 < Sinatra::Base

  get '/round_2/' do
    erb :'round_2/index.html'
  end

  get '/round_2/styles.css' do
    erb :'round_2/styles.css', content_type: 'text/css'
  end

  get '/round_2/all_meals.js' do
    meals = CouchDB::get(CouchDB::uri("_design/round_2/_view/all_meals"))
    puts "Meals: ", meals
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

    erb :'round_2/all_meals.js', content_type: 'application/javascript'
  end

  get '/round_2/yearly_meals.js' do
    meals = CouchDB::get(CouchDB::uri("_design/round_2/_view/all_meals"))
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

    erb :'round_2/yearly_meals.js', content_type: 'application/javascript'
  end

  get '/round_2/monthly_meals_in_last_year.js' do
    today = Date.today
    meals = 
      CouchDB::get(
        CouchDB::uri(
          URI.escape(
            %{_design/round_2/_view/all_meals?start_key=["#{today.year-1}","#{"%02d" % today.month}"]}
          )))

    @months = Hash.new
    @month_list = []
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
      entry = "          [#{day}, #{number_served}]"

      # Either instantiate or add to the year's array of values.
      key = "#{Date::MONTHNAMES[month+1]} #{year}"
      if @months.has_key? key
        @months[key] << entry
      else
        @months[key] = [entry]
      end
      @month_list << key unless @month_list.include? key
    end

    erb :'round_2/monthly_meals_in_last_year.js', content_type: 'application/javascript'
  end

  get '/round_2/monthly_meals_year_over_year/:month' do
    month = params[:month]
    @month_number = Date::MONTHNAMES.index(month)
    erb :'round_2/monthly_meals_year_over_year.html'
  end

  get '/round_2/monthly_meals_year_over_year/:month/chart' do
    month_number = params[:month].to_i
    if month_number < 1 || month_number > 12
      redirect '/round_1/index.html'
    end

    @month_name = Date::MONTHNAMES[month_number]
    start_key = "%02d" % month_number
    end_key = "%02d" % (month_number+1)
    meals = 
      CouchDB::get(
        CouchDB::uri(
          URI.escape(
            %{_design/round_2/_view/monthly_meals?start_key=["#{start_key}"]&end_key=["#{end_key}"]}
          )))

    @months = Hash.new
    @month_list = []
    meals[:rows]&.each do |obj|
      # obj is a Hash with the following keys:
      #   _id: the document ID
      #   key: [month (1-12), year]
      #   value: [day of month, number of meals served]

      # Parse out all the bits for readability, clarity, and DRYness.
      month = Integer(obj[:key][0], 10) - 1   # In JS, months range from 0 through 11.
      year = obj[:key][1]
      day = obj[:value][0]
      number_served = obj[:value][1]

      # Render a line of text for the current entry.
      entry = "[#{day}, #{number_served}]"

      # Either instantiate or add to the year's array of values.
      if @months.has_key? year
        @months[year] << entry
      else
        @months[year] = [entry]
      end
      @month_list << year unless @month_list.include? year
    end

    erb :'round_2/monthly_meals_year_over_year.js', content_type: 'application/javascript'
  end

  get '/round_2/christmas_needs.js' do
    # First, compute the dates we'll need to reference.
    DAYS_BEFORE = 14
    dinner_this_year = Date.parse(CouchDB::get(CouchDB::uri(CouchDB::token('christmas/2019')))[:dates][:dinner])
    dinner_last_year = Date.parse(CouchDB::get(CouchDB::uri(CouchDB::token('christmas/2018')))[:dates][:dinner])
    cutoff_this_year = dinner_this_year - DAYS_BEFORE
    cutoff_last_year = dinner_last_year - DAYS_BEFORE

    # Retrieve the raw data from the view.
    key_2018 = CouchDB::token('["2018"]')
    key_2019 = CouchDB::token('["2019"]')
    raw_data_this_year = CouchDB::get(CouchDB::uri("_design/round_2/_view/christmas_needs?start_key=#{key_2019}"))
    raw_data_last_year =
      CouchDB::get(CouchDB::uri("_design/round_2/_view/christmas_needs?start_key=#{key_2018}&end_key=#{key_2019}"))

    # Process this year's data for each need, collecting results into the needs Hash and building the category list.
    needs = Hash.new
    @categories = []
    raw_data_this_year[:rows]&.each do |row|
      need_slug = row[:key][1].to_sym
      goal = row[:value][:goal]

      # Note: in CouchDB, adjustments should be an array of objects but is just a single object.
      adjustment = row[:value][:adjustment].to_i

      this_year_so_far =  # Note: we only need to filter these for the demo; the live product will show live totals.
        row[:value][:sign_ups]
        .select { |hash| Date.parse(hash[:created_at]) < cutoff_this_year }   # Filter by cutoff.
        .map { |hash| hash[:quantity] }   # Keep only quantity.
        .reduce(0, :+)
      this_year_so_far += adjustment

      needs[need_slug] = {
        this_year: (this_year_so_far.to_f / goal * 100).to_i
      }

      # Note: we do NOT want to use the title of each need, because it might contain distracting information
      # like "on 12/14 and 12/17". Better to transform the need slug.
      @categories << need_slug.to_s.gsub('_', ' ').capitalize
    end

    # Process last year's data, collecting results into the needs Hash.
    raw_data_last_year[:rows]&.each do |row|
      need_slug = row[:key][1].to_sym
      goal = row[:value][:goal]

      # Note: in CouchDB, adjustments should be an array of objects but is just a single object.
      adjustment = row[:value][:adjustment].to_i

      last_year_so_far =  # Note: we still still need to filter last year's result in production.
        row[:value][:sign_ups]
        .select { |hash| Date.parse(hash[:created_at]) < cutoff_last_year }   # Filter by cutoff.
        .map { |hash| hash[:quantity] }   # Keep only quantity.
        .reduce(0, :+)
      last_year_so_far += adjustment

      last_year_total =
        row[:value][:sign_ups]
        .reject { |hash| Date.parse(hash[:created_at]) < cutoff_last_year }   # Keep only after cutoff.
        .map { |hash| hash[:quantity] }   # Keep only quantity.
        .reduce(0, :+)
      last_year_total

      if needs.has_key? need_slug
        needs[need_slug][:last_year] = (last_year_so_far.to_f / goal * 100).to_i
        needs[need_slug][:last_year_total] = (last_year_total.to_f / goal * 100).to_i
      end   # No else clause, because if it doesn't exist this year, then we don't even want to show it.
    end

    # At this point, needs has one key for each need_slug in this year's data set. Each value is a Hash.
    # Each value hash has a key :this_year holding this year's total of sign-ups so far.
    # Each value hash might or might not have two additional keys:
    #   :last_year holds the total for last year by the same number of days before the event.
    #   :last_year_total holds the total for last year overall.
    #
    # Now, we need to scan through these three keys, pulling the values into one of three matching arrays.
    # The reason we held these in a Hash is to guarantee that we will iterate over them in the same order,
    # even in the presence of missing or new need_slugs or other anomalies.
    #
    # Note: adding || 0 to the end of each map transforms nils (due to missing keys) into 0 values that JS will accept.

    @data_this_year = needs.map { |need_slug, hash| hash[:this_year] || 0 }
    @data_last_year = needs.map { |need_slug, hash| hash[:last_year] || 0 }
    @data_last_year_total = needs.map { |need_slug, hash| hash[:last_year_total] || 0 }

    erb :'/round_2/christmas_needs.js', content_type: 'application/javascript'
  end

  get '/round_2/christmas_needs.css' do
    key_2019 = CouchDB::token('["2019"]')
    raw_data_this_year = CouchDB::get(CouchDB::uri("_design/round_2/_view/christmas_needs?start_key=#{key_2019}"))
    @need_count = raw_data_this_year[:rows]&.length

    erb :'/round_2/christmas_needs.css', content_type: 'text/css'
  end

end
