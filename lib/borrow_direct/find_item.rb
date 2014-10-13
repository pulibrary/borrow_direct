require 'borrow_direct'
require 'borrow_direct/request'

module BorrowDirect
  # The BorrowDirect FindItem service, for discovering item availability
  # http://borrowdirect.pbworks.com/w/file/83346676/Find%20Item%20Service.docx
  #
  #     BorrowDirect::FindItem.new(patron_barcode).bd_requestability?(:isbn => isbn)
  #     # or set BorrowDirect::Defaults.find_item_patron_barcode to make patron barcode
  #     # optional and use a default patron barcode
  #
  # You can also use #find_item_request to get the raw BD response as a ruby hash
  class FindItem < Request
    attr_reader :patron_barcode, :patron_library_symbol

    @@api_path = "/dws/item/available"
    @@valid_search_types = %w{ISBN ISSN LCCN OCLC PHRASE}


    def initialize(patron_barcode = Defaults.find_item_patron_barcode, 
                   patron_library_symbol = Defaults.library_symbol)
      super(@@api_path)

      @patron_barcode        = patron_barcode
      @patron_library_symbol = patron_library_symbol
    end

    # need to send a key and value for a valid exact_search type
    # type can be string or symbol, lowercase or uppercase. 
    #
    # Returns the actual complete BD response hash. You may want
    # #bd_requestable? instead
    #
    #    finder.find(:isbn => "12345545456")
    #    finder.find(:lccn => "12345545456")
    #    finder.find(:oclc => "12345545456")
    def find_item_request(options)
      search_type, search_value = nil, nil
      options.each_pair do |key, value|
        if @@valid_search_types.include? key.to_s.upcase
          if search_type || search_value
            raise ArgumentError.new("Only one search criteria at a time is allowed: '#{options}'")
          end

          search_type, search_value = key, value
        end
      end
      unless search_type && search_value
        raise ArgumentError.new("Missing valid search type and value: '#{options}'")
      end

      type = options.keys.first.to_s.upcase
      value = options.values.first

      request exact_search_request_hash(search_type, search_value)
    end

    # need to send a key and value for a valid exact_search type
    # type can be string or symbol, lowercase or uppercase. 
    #
    # Returns true or false -- can the item actually be requested
    # via BorrowDirect. 
    #
    #    finder.bd_requestable? :isbn => "12345545456"
    def bd_requestable?(options)
      resp = find_item_request(options)

      # Items that are available locally, and thus not requestable via BD, can
      # only be found by looking at the RequestMessage, bah
      h = resp["Item"]["RequestLink"]
      if h && h["RequestMessage"] == "This item is available locally"
        return false
      end

      return resp["Item"]["Available"].to_s == "true"
    end

    protected

    def exact_search_request_hash(type, value)
      {
          "PartnershipId" => Defaults.partnership_id,
          "Credentials" => {
              "LibrarySymbol" => self.patron_library_symbol,
              "Barcode" => self.patron_barcode
          },
          "ExactSearch" => [
              {
                  "Type" => type.to_s.upcase,
                  "Value" => value
              }
          ]
      }
    end


  end
end