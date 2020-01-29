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
        puts Net::HTTP.post(uri, doc, JSON_HEADER)
    end
end
