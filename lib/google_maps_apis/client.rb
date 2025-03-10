require 'faraday'
#require 'faraday/retry'
require 'multi_json'
require 'thread'

require 'google_maps_apis/errors'
require 'google_maps_apis/convert'
require 'google_maps_apis/url'
require 'google_maps_apis/services/directions'
require 'google_maps_apis/services/distance_matrix'
require 'google_maps_apis/services/elevation'
require 'google_maps_apis/services/geocoding'
require 'google_maps_apis/services/roads'
require 'google_maps_apis/services/time_zone'
require 'google_maps_apis/services/places'

module GoogleMapsApis

  # Core client functionality, common across all API requests (including performing
  # HTTP requests).
  class Client
    # Default Google Maps Web Service base endpoints
    DEFAULT_BASE_URL = 'https://maps.googleapis.com'

    # Errors those could be retriable.
    RETRIABLE_ERRORS = [GoogleMapsApis::Error::ServerError, GoogleMapsApis::Error::RateLimitError]

    include GoogleMapsApis::Services::Directions
    include GoogleMapsApis::Services::DistanceMatrix
    include GoogleMapsApis::Services::Elevation
    include GoogleMapsApis::Services::Geocoding
    include GoogleMapsApis::Services::Roads
    include GoogleMapsApis::Services::TimeZone
    include GoogleMapsApis::Services::Places

    # Secret key for accessing Google Maps Web Service.
    # Can be obtained at https://developers.google.com/maps/documentation/geocoding/get-api-key#key.
    # @return [String]
    attr_accessor :key

    # Client id for using Maps API for Work services.
    # @return [String]
    attr_accessor :client_id

    # Client secret for using Maps API for Work services.
    # @return [String]
    attr_accessor :client_secret

    # Timeout across multiple retriable requests, in seconds.
    # @return [Integer]
    attr_accessor :retry_timeout

    # Number of queries per second permitted.
    # If the rate limit is reached, the client will sleep for
    # the appropriate amount of time before it runs the current query.
    # @return [Integer]
    attr_reader :queries_per_second

    # Construct Google Maps Web Service API client.
    #
    # You can configure `Hurley::Client` through `request_options` and `ssl_options` parameters.
    # You can also directly get the `Hurley::Client` object via {#client} method.
    #
    # @example Setup API keys
    #   gmaps = GoogleMapsApis::Client.new(key: 'Add your key here')
    #
    # @example Setup client IDs
    #   gmaps = GoogleMapsApis::Client.new(
    #       client_id: 'Add your client id here',
    #       client_secret: 'Add your client secret here'
    #   )
    #
    # @example Setup time out and QPS limit
    #   gmaps = GoogleMapsApis::Client.new(
    #       key: 'Add your key here',
    #       retry_timeout: 20,
    #       queries_per_second: 10
    #   )
    #
    # @example Request behind proxy
    #   request_options = Hurley::RequestOptions.new
    #   request_options.proxy = Hurley::Url.parse 'http://user:password@proxy.example.com:3128'
    #
    #   gmaps = GoogleMapsApis::Client.new(
    #       key: 'Add your key here',
    #       request_options: request_options
    #   )
    #
    # @example Using Excon and Http Cache
    #  require 'hurley-excon'       # https://github.com/lostisland/hurley-excon
    #  require 'hurley/http_cache'  # https://github.com/plataformatec/hurley-http-cache
    #
    #  gmaps = GoogleMapsApis::Client.new(
    #      key: 'Add your key here',
    #      connection: Hurley::HttpCache.new(HurleyExcon::Connection.new)
    #  )
    #
    # @option options [String] :key Secret key for accessing Google Maps Web Service.
    #   Can be obtained at https://developers.google.com/maps/documentation/geocoding/get-api-key#key.
    # @option options [String] :client_id Client id for using Maps API for Work services.
    # @option options [String] :client_secret Client secret for using Maps API for Work services.
    # @option options [Integer] :retry_timeout Timeout across multiple retriable requests, in seconds.
    # @option options [Integer] :queries_per_second Number of queries per second permitted.
    #
    # @option options [Hurley::RequestOptions] :request_options HTTP client request options.
    #     See https://github.com/lostisland/hurley/blob/master/lib/hurley/options.rb.
    # @option options [Hurley::SslOptions] :ssl_options HTTP client SSL options.
    #     See https://github.com/lostisland/hurley/blob/master/lib/hurley/options.rb.
    # @option options [Object] :connection HTTP client connection.
    #     By default, the default Hurley's HTTP client connection (Net::Http) will be used.
    #     See https://github.com/lostisland/hurley/blob/master/README.md#connections.
    def initialize(**options)
      [:key, :client_id, :client_secret,
          :retry_timeout, :queries_per_second,
          :request_options, :ssl_options, :connection].each do |key|
        self.instance_variable_set("@#{key}".to_sym, options[key] || GoogleMapsApis.instance_variable_get("@#{key}"))
      end

      initialize_query_tickets
    end

    # Get the current HTTP client.
    # @return [Faraday::Client]
    def client
      @client ||= new_client
    end

    protected

    # Initialize QPS queue. QPS queue is a "tickets" for calling API
    def initialize_query_tickets
      if @queries_per_second
        @qps_queue = SizedQueue.new @queries_per_second
        @queries_per_second.times do
          @qps_queue << 0
        end
      end
    end

    # Create a new HTTP client.
    # @return [Faraday::Connection]
    def new_client
      client = Faraday.new(DEFAULT_BASE_URL)
      #client.request_options.query_class = Hurley::Query::Flat
      #client.request_options.redirection_limit = 0
      client.headers[:user_agent] = user_agent

      #client.connection = @connection if @connection
      #@request_options.each_pair {|key, value| client.request_options[key] = value } if @request_options
      #@ssl_options.each_pair {|key, value| client.ssl_options[key] = value } if @ssl_options

      client
    end

    # Build the user agent header
    # @return [String]
    def user_agent
      sprintf('google-maps-services-ruby/%s %s',
              GoogleMapsApis::VERSION,
              GoogleMapsApis::OS_VERSION)
    end

    # Make API call.
    #
    # @param [String] path Url path.
    # @param [String] params Request parameters.
    # @param [String] base_url Base Google Maps Web Service API endpoint url.
    # @param [Boolean] accepts_client_id Sign the request using API {#keys} instead of {#client_id}.
    # @param [Method] custom_response_decoder Custom method to decode raw API response.
    #
    # @return [Object] Decoded response body.
    def get(path, params, base_url: DEFAULT_BASE_URL, accepts_client_id: true, custom_response_decoder: nil)
      url = base_url + generate_auth_url(path, params, accepts_client_id)

      #Retriable.retriable timeout: @retry_timeout, on: RETRIABLE_ERRORS do |try|
        #begin
          #request_query_ticket
          response = client.get url
        #ensure
          #release_query_ticket
        #end

        return custom_response_decoder.call(response) if custom_response_decoder
        decode_response_body(response)
      #end
    end

    # Get/wait the request "ticket" if QPS is configured.
    # Check for previous request time, it must be more than a second ago before calling new request.
    #
    # @return [void]
    def request_query_ticket
      if @qps_queue
        elapsed_since_earliest = Time.now - @qps_queue.pop
        sleep(1 - elapsed_since_earliest) if elapsed_since_earliest.to_f < 1
      end
    end

    # Release request "ticket".
    #
    # @return [void]
    def release_query_ticket
      @qps_queue << Time.now if @qps_queue
    end

    # Returns the path and query string portion of the request URL,
    # first adding any necessary parameters.
    #
    # @param [String] path The path portion of the URL.
    # @param [Hash] params URL parameters.
    # @param [Boolean] accepts_client_id Sign the request using API {#keys} instead of {#client_id}.
    #
    # @return [String]
    def generate_auth_url(path, params, accepts_client_id)
      # Deterministic ordering through sorting by key.
      # Useful for tests, and in the future, any caching.
      if params.kind_of?(Hash)
        params = params.sort
      else
        params = params.dup
      end

      if accepts_client_id and @client_id and @client_secret
        params << ["client", @client_id]

        path = [path, GoogleMapsApis::Url.urlencode_params(params)].join("?")
        sig = GoogleMapsApis::Url.sign_hmac(@client_secret, path)
        return path + "&signature=" + sig
      end

      if @key
        params << ["key", @key]
        return path + "?" + GoogleMapsApis::Url.urlencode_params(params)
      end

      raise ArgumentError, "Must provide API key for this API. It does not accept enterprise credentials."
    end

    # Extract and parse body response as hash. Throw an error if there is something wrong with the response.
    #
    # @param [Faraday::Response] response Web API response.
    #
    # @return [Hash] Response body as hash. The hash key will be symbolized.
    def decode_response_body(response)
      check_response_status(response)
      body = MultiJson.load(response.body, :symbolize_keys => true)
      check_body_error(response, body)
      body
    end

    # Check HTTP response status code. Raise error if the status is not 2xx.
    #
    # @param [Faraday::Response] response Web API response.
    def check_response_status(response)
      case response.status
      when 200..300
        # Do-nothing
      when 301...308
        raise GoogleMapsApis::Error::RedirectError.new(response),
          (GoogleMapsApis::Error::RedirectError::ERRORS_3XX[response.status.to_s] + sprintf('Redirect to %s', response.headers[:location]))
      when 400...409,415,422,429
        raise GoogleMapsApis::Error::ClientError.new(response),
          GoogleMapsApis::Error::ClientError::ERRORS_4XX[response.status.to_s]
      when 410...500
        raise GoogleMapsApis::Error::ClientError.new(response), 'Invalid request'
      when 500..600
        raise GoogleMapsApis::Error::ServerError.new(response), 'Server error'
      end
    end

    # Check response body for error status.
    #
    # @param [Faraday::Response] response Response object.
    # @param [Hash] body Response body.
    #
    # @return [void]
    def check_body_error(response, body)
      case body[:status]
      when 'OK', 'ZERO_RESULTS'
        # Do-nothing
      when 'OVER_QUERY_LIMIT'
        raise GoogleMapsApis::Error::RateLimitError.new(response), body[:error_message]
      when 'REQUEST_DENIED'
        raise GoogleMapsApis::Error::RequestDeniedError.new(response), body[:error_message]
      when 'INVALID_REQUEST'
        raise GoogleMapsApis::Error::InvalidRequestError.new(response), body[:error_message]
      when 'NOT_FOUND'
        raise GoogleMapsApis::Error::NotFoundError.new(response), (body[:error_message] || 'ADDRESS NOT FOUND')
      else
        raise GoogleMapsApis::Error::ApiError.new(response), body[:error_message]
      end
    end
  end
end
