class HttpCache
  Meta = Struct.new(:method, :path, :params, :headers) do
    def to_s
      "#{method}#{path}#{params}#{headers}"
    end
  end

  DEFAULT_TTL = 1.hour

  def initialize(app, options = { ttl: DEFAULT_TTL, rescue: false, enable_logger: true })
    @app = app
    @default_ttl = options[:ttl]
    @rescue = options[:rescue]
    @enable_logger = options[:enable_logger]
  end

  def call(env)
    # Group of logs to be printed in the console
    Rails.logger.debug "=" * 50 if @enable_logger

    # Build meta store
    build_meta_store(env)

    # Read from cache
    cached_response = read_from_cache

    return [200, {}, [cached_response]] if cached_response.present?

    # If cache miss, call the app
    Rails.logger.debug "Cache miss for key: #{cache_key}" if @enable_logger
    status, headers, response = @app.call(env)

    # Store in cache
    store_in_cache(response.body)

    # End group of lof
    Rails.logger.debug "=" * 50 if @enable_logger

    # Return
    [status, headers, response]
  end

  def build_meta_store(env)
    request_method = env['REQUEST_METHOD']
    request_path = env['PATH_INFO']
    request_params = Rack::Request.new(env).params
    allowed_headers = ['CONTENT_LANGUAGE', 'ACCEPT', 'AUTHORIZATION']
    request_headers = ActionDispatch::Http::Headers.from_hash(env).select do |key, value|
      key.upcase.in?(allowed_headers)
    end

    # Group of logs to be printed in the console
    # when the request is made
    Rails.logger.debug "Request method: #{request_method}" if @enable_logger
    Rails.logger.debug "Request path: #{request_path}" if @enable_logger
    Rails.logger.debug "Request params: #{request_params}" if @enable_logger
    Rails.logger.debug "Request headers: #{request_headers}" if @enable_logger

    @meta = Meta.new(request_method, request_path, request_params, request_headers)
  end

  def store_in_cache(payload)
    begin
      Rails.cache.write(self.cache_key, payload, expires_in: @default_ttl)
    rescue => e
      # Safe rescue
      Rails.logger.error "Error while storing in cache: #{e.full_message}" if @rescue
      # If rescue is false, raise the error
      raise e unless @rescue
    end
  end

  def read_from_cache
    # Read from Rails cache and return if present
    response_json = Rails.cache.read(cache_key)
    return unless response_json.present?

    Rails.logger.debug "Cache hit for key: #{cache_key}" if @enable_logger
    begin
      response_json
    rescue => e
      # Safe rescue
      Rails.logger.error "Error while reading from cache: #{e.full_message}" if @rescue
      # If rescue is false, raise the error
      raise e unless @rescue
    end
  end

  def cache_key
    "http_cache-#{@meta.to_s}"
  end
end
