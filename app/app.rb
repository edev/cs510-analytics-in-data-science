require_relative '../db/lib/couchdb'
require 'date'
require 'sinatra/base'

class Root < Sinatra::Base

  set :public_folder, File.dirname(__FILE__) + '/static'

  # Serve the landing page.
  get '/' do
    send_file File.expand_path('index.html', settings.public_folder)
  end
end

