module GoogleMapsApis
  # Specific Google Maps Service error
  module Error
    # Base error, capable of wrapping another
    class BaseError < StandardError
      # HTTP response object
      # @return [Faraday::Response]
      attr_reader :response

      # Initialize error
      #
      # @param [Faraday::Response] response HTTP response.
      def initialize(response = nil)
        @response = response
      end
    end

    # The response redirects to another URL.
    class RedirectError < BaseError
      ERRORS_3XX = {
        '300' => 'Multiple Choices',
        '301' => 'Moved Permanently',
        '302' => 'Found',
        '303' => 'See Other',
        '304' => 'Not Modified',
        '305' => 'Use Proxy',
        '306' => 'Switch Proxy',
        '307' => 'Temporary Redirect',
        '308' => 'Permanent Redirect'
      }
    end

    # A 4xx class HTTP error occurred.
    # The request is invalid and should not be retried without modification.
    class ClientError < BaseError
      ERRORS_4XX = {
        '400' => 'Bad Request',
        '401' => 'Unauthorized',
        '402' => 'Payment Required',
        '403' => 'Forbidden',
        '404' => 'Not Found',
        '405' => 'Method Not Allowed',
        '406' => 'Not Acceptable',
        '407' => 'Proxy Authentication Required',
        '408' => 'Request Timeout',
        '409' => 'Conflict',
        '415' => 'Unsupported Media Type',
        '422' => 'Unprocessable Entity',
        '429' => 'Too Many Requests'
      }
    end

    # A 5xx class HTTP error occurred.
    # An error occurred on the server and the request can be retried.
    class ServerError < BaseError
    end

    # An unknown error occured.
    class UnknownError < BaseError
    end

    # General Google Maps Web Service API error occured.
    class ApiError < BaseError
    end

    # Requiered query is missing
    class InvalidRequestError < ApiError
    end

    # The quota for the credential is over limit.
    class RateLimitError < ApiError
    end

    # An unathorized error occurred. It might be caused by invalid key/secret or invalid access.
    class RequestDeniedError < ApiError
    end

    # When an Address is not found. i.e. An address string could not be geocoded
    class NotFoundError < ApiError
    end
  end
end