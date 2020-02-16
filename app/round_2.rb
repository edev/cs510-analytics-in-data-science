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

  get '/round_2/christmas_needs/:need_type' do
    @need_type = params[:need_type]
    erb :'round_2/christmas_needs.html'
  end

  get '/round_2/christmas_needs/:need_type/chart' do
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

      # Note: we could optimize this by moving page to the key, then sorting & filtering accordingly.
      page = row[:value][:page]
      next unless page == params[:need_type]

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

  ##
  # Returns a needs hash suitable for rendering various Christmas charts.
  #
  # Arguments:
  #   need_type: a string for the need type that will match against CouchDB documents' page fields, e.g. 'volunteer'
  #     or 'donate'.
  #   years: a collection of years, where the first item in the collection (when enumerated) dictates which needs
  #     are included and which ones are not. For instance, given [2019, 2018, 2017], only needs present in 2019 will
  #     be part of the returned needs Hash. The years may be arbitrary and will be processed individually in
  #     enumeration order.
  #   cutoff: the number of days before the event that we suppose might remain when the user views a visualization.
  #     Presumably this is 14. 0 is untested but might work. Negative numbers are untested and discouraged. Fractional
  #     or decimal numbers are discouraged.
  #
  # The first year in years is referred to in this function as the canonical year, as it defines the canonical list
  # of needs.
  #
  # The a needs Hash associates each need_slug with a Hash that has the following keys:
  #   :goal is the need's goal according to the canonical year.
  #   :current is the canonical year's :so_far value.
  #   :percent is the canonical year's :so_far value as a percent of goal.
  #   :years is a Hash with one key for each year we opted to include in the code above.
  #     The value for each year is a Hash with the following keys:
  #       :so_far holds the percentage of sign-ups toward the goal as of the cutoff number of days before the event.
  #       :final (present for all years except the canonical year) holds the percentage of sign-ups toward the goal,
  #         counting only those that came in after the cutoff for :so_far.
  #
  # Note: Percents are stored as integers, e.g. 53 for 53%.
  #
  # Example:
  #
  # needs_for('volunteers', (2017..2019).to_a.reverse, 14) =>
  # {
  #   hot_chocolatiers: {
  #     goal: 120,
  #     current: 300,
  #     percent: 250,
  #     years: {
  #       2017: {
  #         so_far: 12,
  #         final: 7
  #       },
  #       2018: {
  #         so_far: 89,
  #         final: 6
  #       },
  #       2019: {   # 2019 == the canonical year
  #         so_far: 300   # Perhaps we received way too many sign-ups.
  #       }
  #     }
  #   },
  #   ...
  # }
  def needs_for(need_type, years, cutoff)
    canonical_year = years[0]
    cutoff = 14

    dinner_dates = {}
    cutoff_dates = {}
    raw_data = {}
    years.each do |year| 
      # Compute the dates we'll need to reference.
      dinner_dates[year] = Date.parse(CouchDB::get(CouchDB::uri(CouchDB::token("christmas/#{year}")))[:dates][:dinner])
      cutoff_dates[year] = dinner_dates[year] - cutoff

      # Retrieve raw data from the view.
      start_key = CouchDB::token %{["#{year}"]}
      end_key = CouchDB::token %{["#{year + 1}"]}
      raw_data[year] = 
        CouchDB::get(CouchDB::uri("_design/round_2/_view/christmas_needs?start_key=#{start_key}&end_key=#{end_key}"))
    end

    # Process each year's data for each need, collecting results into the needs Hash.

    needs = Hash.new
    raw_data.each do |year, raw_data|
      raw_data[:rows]&.each do |row|
        need_slug = row[:key][1].to_sym
        goal = row[:value][:goal]

        # Note: we could optimize this by moving page to the key, then sorting & filtering accordingly.
        page = row[:value][:page]
        next unless page == need_type

        if year == canonical_year
          # Add this need to the data structures we're building.

          # Note for future Dylan:
          #
          # Since this code deals with arbitrary numbers of years' data, it's necessary to consider the possibility
          # that the list or names of needs might change between years. The correct way is to do the following:
          #
          # 1. ONLY include needs in the needs Hash if they are present THIS YEAR.
          # 2. Pull all names, etc. from this year's set of names.

          needs[need_slug] = {
            goal: goal,
            years: {}
          }

          # Note: we do NOT want to use the title of each need, because it might contain distracting information
          # like "on 12/14 and 12/17". Better to transform the need slug.
        elsif !needs.has_key? need_slug
          # The current year doesn't have this need, so exclude it from the data set.
          next
        end

        # Note: in CouchDB, adjustments should be an array of objects but is just a single object.
        adjustment = row[:value][:adjustment].to_i

        year_so_far =
          row[:value][:sign_ups]
          .select { |hash| Date.parse(hash[:created_at]) < cutoff_dates[year] }   # Filter by cutoff.
          .map { |hash| hash[:quantity] }                                         # Keep only quantities.
          .reduce(0, :+)                                                          # Sum quantities.
        year_so_far += adjustment                                                 # Add adjustments.

        # Fill in the current year's progress and percentage.
        needs[need_slug][:current] = year_so_far
        needs[need_slug][:percent] = (year_so_far.to_f / goal * 100).to_i
        needs[need_slug][:years][year] = {
          so_far: needs[need_slug][:current]
        }

        year_final =
          row[:value][:sign_ups]
          .reject { |hash| Date.parse(hash[:created_at]) < cutoff_dates[year] }   # Keep only after cutoff.
          .map { |hash| hash[:quantity] }                                         # Keep only quantity.
          .reduce(0, :+)                                                          # Sum quantities.

        # Fill in the current year's percentage for the last cutoff days, except for the current year.
        needs[need_slug][:years][year][:final] = year_final unless year == canonical_year
      end
    end
    needs
  end

  get '/round_2/christmas_needs/sparklines/:need_type' do
    @need_type = params[:need_type]
    @needs = needs_for(@need_type, (2016..2019).to_a.reverse, 14)

    erb :'/round_2/christmas_needs_sparklines.html'
  end

  get '/round_2/christmas_needs/sparklines/:need_type/chart' do
    @need_type = params[:need_type]

    erb :'/round_2/christmas_needs_sparklines.js', content_type: 'application/javascript'
  end

  get '/round_2/christmas_needs/gauges/:need_type' do
    @need_type = params[:need_type]
    @needs = needs_for(@need_type, (2016..2019).to_a.reverse, 14)

    erb :'/round_2/christmas_needs_gauges.html'
  end

  get '/round_2/christmas_needs/gauges/:need_type/chart' do
    @need_type = params[:need_type]

    erb :'/round_2/christmas_needs_gauges.js', content_type: 'application/javascript'
  end

end
