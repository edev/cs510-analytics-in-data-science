require 'net/http'
require 'json'

module CouchDB
  HOSTNAME = 'localhost'
  PORT = 5984
  DB = 'bounty'
  JSON_HEADER = { 'Content-Type': 'application/json' }

  ##
  # Helper method to generate a URI object for a CouchDB path.
  #
  # The helper will auto-fill everything from http:// through the database name and trailing slash. To get the URI of
  # the database itself, pass path="". For any subpath, provide just the subpath portion of the URI. For instance,
  # to access the CouchDB API path /{db}/_design/{design-doc} for a design document named foo, pass path='_design/foo'.
  #
  # Any queries or fragments, e.g. "?foo=bar#baz", should be passed in path as well.
  #
  # Returns a URI object appropriate for a CouchDB request.
  def self.uri(path)
    URI("http://#{HOSTNAME}:#{PORT}/#{DB}/#{path}")
  end

  ##
  # Converts a Ruby object (typically a Hash) to JSON, then uploads it to the database.
  def self.post_document(obj)
    doc = JSON.generate(obj)
    uri = uri('')
    $stdout.puts Net::HTTP.post(uri, doc, JSON_HEADER)
  end

  ##
  # Converts a Ruby object (typically a Hash) to JSON, then uploads it to the database as a design document.
  def self.put_ddoc(name, obj)
    doc = JSON.generate(obj)
    uri = uri("_design/#{name}")
    p uri
    request = Net::HTTP::Put.new(uri)

    Net::HTTP.start(uri.hostname, uri.port) do |http|
      $stdout.puts http.request(request, doc)
    end
  end
end
