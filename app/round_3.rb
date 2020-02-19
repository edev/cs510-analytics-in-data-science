require 'sinatra/base'

class Round3 < Sinatra::Base

  get '/round_3/' do
    erb :'round_3/index.html'
  end

  get '/round_3/styles.css' do
    erb :'round_3/styles.css', content_type: 'text/css'
  end

  get '/round_3/all_meals.js' do
    meals = CouchDB::get(CouchDB::uri("_design/round_3/_view/all_meals"))
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

    erb :'round_3/all_meals.js', content_type: 'application/javascript'
  end

  get '/round_3/yearly_meals.js' do
    meals = CouchDB::get(CouchDB::uri("_design/round_3/_view/all_meals"))
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

    erb :'round_3/yearly_meals.js', content_type: 'application/javascript'
  end

  get '/round_3/monthly_meals_in_last_year.js' do
    today = Date.today
    meals = 
      CouchDB::get(
        CouchDB::uri(
          URI.escape(
            %{_design/round_3/_view/all_meals?start_key=["#{today.year-1}","#{"%02d" % today.month}"]}
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

    erb :'round_3/monthly_meals_in_last_year.js', content_type: 'application/javascript'
  end

  get '/round_3/monthly_meals_year_over_year/:month' do
    month = params[:month]
    @month_number = Date::MONTHNAMES.index(month)
    erb :'round_3/monthly_meals_year_over_year.html'
  end

  get '/round_3/monthly_meals_year_over_year/:month/chart' do
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
            %{_design/round_3/_view/monthly_meals?start_key=["#{start_key}"]&end_key=["#{end_key}"]}
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

    erb :'round_3/monthly_meals_year_over_year.js', content_type: 'application/javascript'
  end

  get '/round_3/christmas_needs.css' do
    erb :'/round_3/christmas_needs.css', content_type: 'text/css'
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
        CouchDB::get(CouchDB::uri("_design/round_3/_view/christmas_needs?start_key=#{start_key}&end_key=#{end_key}"))
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

  get '/round_3/christmas_needs' do
    YEARS = (2016..2019).to_a.reverse
    CUTOFF = 14
    @volunteer_needs = needs_for('volunteer', YEARS, CUTOFF)

    GAUGE_NEED_SLUGS = [
        :choir_singers,
        :present_wrappers,
        :final_cleaner_uppers,
        :gift_buyers,
        :gym_decarators,
        :hot_chocolatiers,
        :line_monitors,
        :santas_elves,
        :sign_makers,
        :snack_server,
    ]

    TABLE_NEED_SLUGS = [
        :choir_coordinator,
        :general_coordinator_for_presents,
        :photographer,
        :piano_player_accompanist,
        :santa,
        :stocking_manager,
        :tech_savvy_photo_printers,
    ]

    @primary_gauges = @volunteer_needs.select { |need_slug, need| GAUGE_NEED_SLUGS.include? need_slug }
    @donation_gauges = needs_for('donate', YEARS, CUTOFF)
    @minor_gauges = @volunteer_needs.reject do |need_slug, need|
      GAUGE_NEED_SLUGS.include?(need_slug) || TABLE_NEED_SLUGS.include?(need_slug)
    end
    @table_rows = @volunteer_needs.select { |need_slug, need| TABLE_NEED_SLUGS.include? need_slug }

    erb :'/round_3/christmas_needs_primary.html'
  end

  get '/round_3/christmas_needs/chart' do
    @need_type = params[:need_type]

    erb :'/round_3/christmas_needs_primary.js', content_type: 'application/javascript'
  end

  get '/round_3/christmas_needs/timeline/:need_slug' do
    @need_slug = params[:need_slug]

    start_key = CouchDB::token %{["#{@need_slug}"]}
    end_key = CouchDB::token %{["#{@need_slug}/{}"]}

    options = [
      "start_key=#{start_key}",
      "end_key=#{end_key}",
      "group=true"
    ].join("&")

    records =
      CouchDB::get(
        CouchDB::uri("_design/round_3/_view/christmas_need_timelines?#{options}"))

    records.inspect
  end

end
