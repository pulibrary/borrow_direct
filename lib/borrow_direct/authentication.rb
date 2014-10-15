require 'borrow_direct/request'

module BorrowDirect

  # The BD Authorization API
  # http://borrowdirect.pbworks.com/w/file/83346673/Authorization%20Service.docx  
  #
  # For now, always calls with 'patron' type. 
  class Authentication < Request
    attr_reader :patron_barcode, :patron_library_symbol

    @@api_path = "/portal-service/user/authentication/patron"

    # BorrowDirect::Authentication.new(barcode)
    # BorrowDirect::Authentication.new(barcode, library_symbol)
    def initialize(patron_barcode, 
                   patron_library_symbol = Defaults.library_symbol)
      super(@@api_path)

      @patron_barcode = patron_barcode
      @patron_library_symbol = patron_library_symbol
    end

    # Returns raw Hash results of the Authentication request
    # See also #get_auth_id
    def authentication_request
      self.request authentication_request_hash(self.patron_barcode, self.patron_library_symbol)
    end

    # Makes a request and returns the "AId" value which is used as input
    # "AuthorizationId" in other API calls. 
    #
    # If one can't be obtained for some reason, will raise BorrowDirect::Error
    def get_auth_id
      response = authentication_request

      if response["Authentication"] && response["Authentication"]["AuthnUserInfo"] && response["Authentication"]["AuthnUserInfo"]["AId"]
        return response["Authentication"]["AuthnUserInfo"]["AId"]
      else
        raise BorrowDirect::Error.new("Could not obtain AId from Authorization API call: #{response.inspect}")
      end
    end

    def authentication_request_hash(patron_barcode, library_symbol)
      {
        "AuthenticationInformation" => {
          "LibrarySymbol" => library_symbol,
          "PatronId" => patron_barcode
        }
      } 
    end

  end

end