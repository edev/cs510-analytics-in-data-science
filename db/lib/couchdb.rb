require 'net/http'
require 'json'

module CouchDB
    HOSTNAME = 'localhost'
    PORT = 5984
    DB = '/bounty'
    JSON_HEADER = { 'Content-Type': 'application/json' }

    ##
    # Helper method to get a URI for a given path.
    def self.uri(path)
        URI::HTTP.build(
          host: HOSTNAME,
          port: PORT,
          path: path
        )
    end
        
    ##
    # Converts a Ruby object (typically a Hash) to JSON, then uploads it to the database.
    def self.post_document(obj)
        doc = JSON.generate(obj)
        uri = uri(DB)
        $stdout.puts Net::HTTP.post(uri, doc, JSON_HEADER)
    end

    ##
    # Converts a Ruby object (typically a Hash) to JSON, then uploads it to the database as a design document.
    def self.put_ddoc(name, obj)
        doc = JSON.generate(obj)
        uri = uri("#{DB}/_design/#{name}")
        p uri
        request = Net::HTTP::Put.new(uri)

        Net::HTTP.start(uri.hostname, uri.port) do |http|
            $stdout.puts http.request(request, doc)
        end

    end
end
